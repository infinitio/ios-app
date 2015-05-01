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
  self.table_view.allowsMultipleSelectionDuringEditing = YES;
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  _folder_results = [self searchAndFilterResults];
  [self.table_view reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  self.editing = NO;
}

#pragma mark - Public

- (CGRect)last_row_rect
{
  NSIndexPath* index = self.table_view.indexPathsForVisibleRows.lastObject;
  return [self.table_view cellForRowAtIndexPath:index].frame;
}

#pragma mark - Editing

- (NSArray*)current_selection
{
  if (!self.editing)
    return nil;
  NSMutableArray* res = [NSMutableArray array];
  for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    [res addObject:self.folder_results[index.row]];
  return res;
}

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
  if (!tableView.editing)
  {
    [self.delegate actionForFolder:self.folder_results[indexPath.row] sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
  }
}

#pragma mark - Files Display

- (void)folderAdded:(InfinitFolderModel*)folder
{
  @synchronized(self)
  {
    if ([self.all_folders containsObject:folder])
      return;
    [super folderAdded:folder];
    if (!self.search_string.length)
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
  @synchronized(self)
  {
    if (![self.all_folders containsObject:folder])
      return;
    [super folderRemoved:folder];
    if (!self.search_string.length)
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

#pragma mark - Search

- (void)setFilter:(InfinitFileTypes)filter
{
  if (self.filter == filter)
    return;
  @synchronized(self)
  {
    [super setFilter:filter];
    _folder_results = [self searchAndFilterResults];
    [self.table_view reloadData];
  }
}

- (void)setSearch_string:(NSString*)search_string
{
  if ([self.search_string isEqualToString:search_string])
    return;
  @synchronized(self)
  {
    [super setSearch_string:search_string];
    if (self.search_string.length)
      _folder_results = [self searchAndFilterResults];
    else
      _folder_results = [self.all_folders mutableCopy];

    [self.table_view reloadData];
  }
}

- (NSMutableArray*)searchAndFilterResults
{
  NSMutableArray* res = [NSMutableArray array];
  for (InfinitFolderModel* folder in self.all_folders)
  {
    if ([folder hasMatchesForType:self.filter] && [folder containsString:self.search_string])
      [res addObject:folder];
  }
  return res;
}

@end
