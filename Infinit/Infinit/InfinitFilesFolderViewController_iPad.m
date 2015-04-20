//
//  InfinitFilesFolderViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesFolderViewController_iPad.h"

#import "InfinitFilesTableCell_iPad.h"

@interface InfinitFilesFolderViewController_iPad () <UITableViewDataSource,
                                                     UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (nonatomic, readonly) NSMutableArray* file_results;

@end

@implementation InfinitFilesFolderViewController_iPad
{
@private
  NSString* _cell_id;
}

- (void)viewDidLoad
{
  _cell_id = [InfinitFilesTableCell_iPad cell_id];
  [super viewDidLoad];
  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesTableCell_iPad.class)
                                   bundle:nil];
  [self.table_view registerNib:cell_nib forCellReuseIdentifier:_cell_id];
  self.table_view.allowsMultipleSelectionDuringEditing = YES;
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  _file_results = [self searchAndFilterResults];
  [self.table_view reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  self.editing = NO;
}

- (void)reload
{
  _file_results = [self searchAndFilterResults];
  [self.table_view reloadData];
}

#pragma mark - Editing

- (NSArray*)current_selection
{
  if (!self.editing)
    return nil;
  NSMutableArray* res = [NSMutableArray array];
  for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    [res addObject:self.file_results[index.row]];
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
    InfinitFileModel* file = self.file_results[indexPath.row];
    [tableView beginUpdates];
    [self.file_results removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
    [self.delegate deleteFile:file sender:self];
  }
}

- (void)filesDeleted
{
  [self.table_view beginUpdates];
  NSMutableArray* temp = [self.file_results mutableCopy];
  [temp removeObjectsInArray:[self searchAndFilterResults]];
  NSMutableArray* indexes = [NSMutableArray array];
  for (InfinitFileModel* file in temp)
  {
    NSUInteger index = [self.file_results indexOfObject:file];
    if (index != NSNotFound)
      [indexes addObject:[NSIndexPath indexPathForRow:index inSection:0]];
  }
  _file_results = [self searchAndFilterResults];
  if (indexes.count > 0)
  {
    [self.table_view deleteRowsAtIndexPaths:indexes
                           withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  [self.table_view endUpdates];
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
  return self.file_results.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell_iPad* cell = [tableView dequeueReusableCellWithIdentifier:_cell_id
                                                                     forIndexPath:indexPath];
  [cell configureForFile:self.file_results[indexPath.row]];
  return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView 
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.editing)
  {

  }
  else
  {
    [self.delegate actionForFile:self.file_results[indexPath.row] sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
    _file_results = [self searchAndFilterResults];
    [self.table_view reloadData];
  }
}

- (void)setSearch_string:(NSString*)search_string
{
  if (self.search_string == search_string)
    return;
  @synchronized(self)
  {
    [super setSearch_string:search_string];
    if (self.search_string.length)
      _file_results = [self searchAndFilterResults];
    else
      _file_results = [self.folder.files mutableCopy];
    [self.table_view reloadData];
  }
}

- (NSMutableArray*)searchAndFilterResults
{
  NSMutableArray* res = [NSMutableArray array];
  for (InfinitFileModel* file in self.folder.files)
  {
    if ([file matchesType:self.filter] && [file containsString:self.search_string])
      [res addObject:file];
  }
  return res;
}

@end
