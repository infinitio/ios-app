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
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
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
    [self.delegate deleteFile:self.folder.files[indexPath.row] sender:self];
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
  return self.folder.files.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell_iPad* cell = [tableView dequeueReusableCellWithIdentifier:_cell_id
                                                                     forIndexPath:indexPath];
  [cell configureForFile:self.folder.files[indexPath.row]];
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
    [self.delegate actionForFile:self.folder.files[indexPath.row] sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
  }
}

@end
