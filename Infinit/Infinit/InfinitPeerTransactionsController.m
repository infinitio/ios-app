//
//  InfinitPeerTransactionsController.m
//  Infinit
//
//  Created by Christopher Crone on 12/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitPeerTransactionsController.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

#import "InfinitPeerTransactionCell.h"

@interface InfinitPeerTransactionsController () <UITableViewDataSource,
                                                 UITableViewDelegate,
                                                 UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end

@implementation InfinitPeerTransactionsController
{
  NSMutableArray* _transactions;
}

#pragma mark - Init

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _transactions = [[[InfinitPeerTransactionManager sharedInstance] transactions] mutableCopy];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionAdded:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newAvatar:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Update Handling

- (void)transactionUpdated:(NSNotification*)notification
{
  NSInteger index = 0;
  @synchronized(_transactions)
  {
    for (InfinitPeerTransaction* transaction in _transactions)
    {
      if ([transaction.id_ isEqual:notification.userInfo[@"id"]])
      {
        InfinitPeerTransactionCell* cell =
          (InfinitPeerTransactionCell*)[self.table_view cellForRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        [cell setupCellWithTransaction:transaction];
        break;
      }
      index++;
    }
  }
}

- (void)transactionAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[@"id"];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [_transactions insertObject:transaction atIndex:0];
  [self.table_view beginUpdates];
  [self.table_view insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
  [self.table_view endUpdates];
}

- (void)newAvatar:(NSNotification*)notification
{
  NSNumber* user_id = notification.userInfo[@"id"];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:user_id];
  NSUInteger indexes[_transactions.count];
  NSUInteger size = 0;
  NSUInteger row = 0;
  @synchronized(_transactions)
  {
    for (InfinitPeerTransaction* transaction in _transactions)
    {
      if ([transaction.other_user isEqual:user])
      {
        indexes[++size] = row;
      }
      row++;
    }
    if (size > 0)
    {
      NSIndexPath* index_path = [NSIndexPath indexPathWithIndexes:indexes length:size];
      [self.table_view beginUpdates];
      [self.table_view reloadRowsAtIndexPaths:@[index_path]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
      [self.table_view endUpdates];
    }
  }
}

#pragma mark - Table

- (NSString*)tableView:(UITableView*)tableView
titleForHeaderInSection:(NSInteger)section
{
  return @"Peer Transactions";
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 100.0f;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  return 75.0f;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  @synchronized(_transactions)
  {
    return _transactions.count;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* identifier = @"peer_transaction_cell";
  InfinitPeerTransactionCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  InfinitPeerTransaction* transaction = _transactions[indexPath.row];
  [cell setupCellWithTransaction:transaction];
  return cell;
}

#pragma mark - Table Interaction

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  InfinitPeerTransaction* transaction = _transactions[self.table_view.indexPathForSelectedRow.row];
  switch (transaction.status)
  {
    case gap_transaction_waiting_accept:
      if (buttonIndex == alertView.firstOtherButtonIndex)
        [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:transaction];
      else if (buttonIndex == alertView.firstOtherButtonIndex + 1)
        [[InfinitPeerTransactionManager sharedInstance] rejectTransaction:transaction];
      break;
    case gap_transaction_paused:
      if (buttonIndex == alertView.firstOtherButtonIndex)
        [[InfinitPeerTransactionManager sharedInstance] resumeTransaction:transaction];
      break;
    case gap_transaction_transferring:
      if (buttonIndex == alertView.firstOtherButtonIndex)
        [[InfinitPeerTransactionManager sharedInstance] pauseTransaction:transaction];
      break;

    default:
      [alertView dismissWithClickedButtonIndex:0 animated:NO];
      break;
  }
  [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:YES];
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  UIAlertView* alert = nil;
  InfinitPeerTransaction* transaction = _transactions[indexPath.row];
  switch (transaction.status)
  {
    case gap_transaction_waiting_accept:
      if (transaction.receivable)
      {
        alert = [[UIAlertView alloc] initWithTitle:@"Accept/Reject"
                                           message:nil
                                          delegate:self
                                 cancelButtonTitle:@"Back"
                                 otherButtonTitles:@"Accept", @"Reject", nil];
      }
      break;
    case gap_transaction_paused:
      alert = [[UIAlertView alloc] initWithTitle:@"Paused"
                                         message:nil
                                        delegate:self
                               cancelButtonTitle:@"Back"
                               otherButtonTitles:@"Resume", nil];
      break;
    case gap_transaction_transferring:
      alert = [[UIAlertView alloc] initWithTitle:@"Running"
                                         message:nil
                                        delegate:self
                               cancelButtonTitle:@"Back"
                               otherButtonTitles:@"Pause", nil];

    default:
      [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:YES];
      return;
  }
  [alert show];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
