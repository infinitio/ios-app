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
  NSArray* _transactions;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _transactions = [[InfinitPeerTransactionManager sharedInstance] transactions];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Table

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  return NO;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 100.0f;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  return 30.0f;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return _transactions.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* identifier = @"peer_transaction_cell";
  InfinitPeerTransactionCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
  {
    cell = [[InfinitPeerTransactionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:identifier];
  }
  InfinitPeerTransaction* transaction = _transactions[indexPath.row];
  [cell setUpCellWithTransaction:transaction];
  return cell;
}

#pragma mark - Table Interaction

- (IBAction)acceptTapped:(UIButton*)sender
{
  CGPoint button_pos = [sender convertPoint:CGPointZero toView:self.table_view];
  NSIndexPath* index = [self.table_view indexPathForRowAtPoint:button_pos];
  if (index != nil)
  {
    InfinitPeerTransactionCell* cell =
      (InfinitPeerTransactionCell*)[self.table_view cellForRowAtIndexPath:index];
  [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:cell.transaction];
  }
}

- (IBAction)rejectTapped:(UIButton*)sender
{
  CGPoint button_pos = [sender convertPoint:CGPointZero toView:self.table_view];
  NSIndexPath* index = [self.table_view indexPathForRowAtPoint:button_pos];
  if (index != nil)
  {
    InfinitPeerTransactionCell* cell =
      (InfinitPeerTransactionCell*)[self.table_view cellForRowAtIndexPath:index];
    [[InfinitPeerTransactionManager sharedInstance] rejectTransaction:cell.transaction];
  }
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
