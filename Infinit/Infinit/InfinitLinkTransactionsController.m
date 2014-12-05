//
//  InfinitLinkTransactionsController.m
//  Infinit
//
//  Created by Christopher Crone on 13/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkTransactionsController.h"
#import "InfinitLinkTransactionCell.h"

#import <Gap/InfinitLinkTransactionManager.h>

@interface InfinitLinkTransactionsController ()

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end

@implementation InfinitLinkTransactionsController
{
  NSMutableArray* _transactions;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _transactions =
    [NSMutableArray arrayWithArray:[[InfinitLinkTransactionManager sharedInstance] transactions]];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Table

- (NSString*)tableView:(UITableView*)tableView
titleForHeaderInSection:(NSInteger)section
{
  return @"Link Transactions";
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 75.0f;
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
  NSString* identifier = @"link_transaction_cell";
  InfinitLinkTransactionCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  InfinitLinkTransaction* transaction = _transactions[indexPath.row];
  [cell setupCellWithTransaction:transaction];
  return cell;
}

#pragma mark - User Interaction

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitLinkTransaction* transaction = _transactions[indexPath.row];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:transaction.link]];
  [self.table_view deselectRowAtIndexPath:indexPath animated:YES];
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
