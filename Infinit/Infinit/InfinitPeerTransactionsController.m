//
//  InfinitPeerTransactionsController.m
//  Infinit
//
//  Created by Christopher Crone on 12/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitPeerTransactionsController.h"

#import <Gap/InfinitPeerTransactionManager.h>

#import "InfinitPeerTransactionCell.h"

@interface InfinitPeerTransactionsController ()

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
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Update Handling

- (void)transactionUpdated:(NSNotification*)notification
{
  @synchronized(_transactions)
  {
    NSInteger index = 0;
    for (InfinitPeerTransaction* transaction in _transactions)
    {
      if ([transaction.id_ isEqual:notification.userInfo[@"id"]])
      {
        [self.table_view beginUpdates];
        [self.table_view reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]
                               withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.table_view endUpdates];
        return;
      }
      index++;
    }
  }
}

- (void)transactionAdded:(NSNotification*)notification
{
  @synchronized(_transactions)
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

- (IBAction)acceptTapped:(UIButton*)sender
{
  CGPoint button_pos = [sender convertPoint:CGPointZero toView:self.table_view];
  NSIndexPath* index = [self.table_view indexPathForRowAtPoint:button_pos];
  if (index != nil)
    [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:_transactions[index.row]];
}

- (IBAction)rejectTapped:(UIButton*)sender
{
  CGPoint button_pos = [sender convertPoint:CGPointZero toView:self.table_view];
  NSIndexPath* index = [self.table_view indexPathForRowAtPoint:button_pos];
  if (index != nil)
    [[InfinitPeerTransactionManager sharedInstance] rejectTransaction:_transactions[index.row]];
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
