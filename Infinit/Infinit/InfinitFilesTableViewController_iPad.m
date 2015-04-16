//
//  InfinitFilesTableViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesTableViewController_iPad.h"

#import "InfinitDownloadFolderManager.h"
#import "InfinitFilesTableCell_iPad.h"
#import "InfinitFolderModel.h"

@interface InfinitFilesTableViewController_iPad () <UITableViewDataSource,
                                                    UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (nonatomic, readonly) NSMutableArray* folder_results;

@end

@implementation InfinitFilesTableViewController_iPad
{
@private
  NSString* _cell_id;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _cell_id = [InfinitFilesTableCell_iPad cell_id];
  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesTableCell_iPad.class)
                                   bundle:nil];
  [self.table_view registerNib:cell_nib forCellReuseIdentifier:_cell_id];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  _folder_results = [self.all_folders mutableCopy];
  [self.table_view reloadData];
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing
{
  if (self.editing == editing)
    return;
  [super setEditing:editing];
  [self.table_view setEditing:editing animated:YES];
}

- (void)tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    [self.delegate deleteFolder:self.folder_results[indexPath.row] sender:self];
    [tableView deleteRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [InfinitFilesTableCell_iPad height];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.folder_results.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell_iPad* cell = [tableView dequeueReusableCellWithIdentifier:_cell_id
                                                                     forIndexPath:indexPath];
  InfinitFolderModel* folder = self.folder_results[indexPath.row];
  [cell configureForFolder:folder];
  return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (tableView.editing)
  {

  }
  else
  {
    [self.delegate actionForFolder:self.folder_results[indexPath.row] sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
  }
}

#pragma mark - Files Display

- (void)setSearching:(BOOL)searching
{
  [super setSearching:searching];
  if (!self.searching)
  {
    _folder_results = [self.all_folders mutableCopy];
    [self.table_view reloadData];
  }
}

- (void)folderAdded:(InfinitFolderModel*)folder
{
  @synchronized(self.all_folders)
  {
    if ([self.all_folders containsObject:folder])
      return;
    [super folderAdded:folder];
    if (!self.searching)
    {
      [self.table_view beginUpdates];
      [self.folder_results insertObject:folder atIndex:0];
      [self.table_view insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
      [self.table_view endUpdates];
    }
  }
}

- (void)folderRemoved:(InfinitFolderModel*)folder
{
  @synchronized(self.all_folders)
  {
    if (![self.all_folders containsObject:folder])
      return;
    [super folderRemoved:folder];
    if (!self.searching)
    {
      [self.table_view beginUpdates];
      NSUInteger index = [self.folder_results indexOfObject:folder];
      [self.folder_results removeObjectAtIndex:index];
      [self.table_view deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
      [self.table_view endUpdates];
    }
  }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end
