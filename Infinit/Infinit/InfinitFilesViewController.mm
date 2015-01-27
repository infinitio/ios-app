//
//  InfinitFilesViewController.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesViewController.h"

#import "InfinitColor.h"
#import "InfinitFilesMultipleViewController.h"
#import "InfinitFilePreviewController.h"
#import "InfinitFilesTableCell.h"
#import "InfinitFolderModel.h"

#import <Gap/InfinitDirectoryManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FilesViewController");

@interface InfinitFilesViewController () <UISearchBarDelegate,
                                          UITableViewDataSource,
                                          UITableViewDelegate>

@property (nonatomic, readonly) NSMutableArray* folders;
@property (nonatomic) UIView* no_files_view;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;

@end

@implementation InfinitFilesViewController
{
@private
  NSString* _file_cell_id;
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _file_cell_id = @"file_table_cell";
  }
  return self;
}

- (void)viewDidLoad
{
  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesTableCell.class) bundle:nil];
  [self.table_view registerNib:cell_nib forCellReuseIdentifier:_file_cell_id];
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  NSMutableArray* res = [NSMutableArray array];
  NSError* error = nil;
  NSString* dir = [InfinitDirectoryManager sharedInstance].download_directory;
  NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&error];
  if (error)
  {
    ELLE_ERR("%s: unable to access downloads directory", self.description.UTF8String);
    [super viewWillAppear:animated];
    return;
  }
  InfinitDirectoryManager* manager = [InfinitDirectoryManager sharedInstance];
  NSString* path;
  for (NSString* folder_name in contents)
  {
    path = [manager.download_directory stringByAppendingPathComponent:folder_name];
    InfinitFolderModel* folder = [[InfinitFolderModel alloc] initWithPath:path];
    [res addObject:folder];
  }
  NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"ctime" ascending:NO];
  _folders = [[res sortedArrayUsingDescriptors:@[sort]] mutableCopy];
  if (self.folders.count == 0)
  {
    [self showNoFilesOverlay];
  }
  else
  {
    if (self.no_files_view != nil)
    {
      [self.no_files_view removeFromSuperview];
      _no_files_view = nil;
    }
    self.search_bar.hidden = NO;
    [self.table_view reloadData];
  }
  [super viewWillAppear:animated];
  if (self.table_view.indexPathForSelectedRow != nil)
    [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:YES];
}

- (void)showNoFilesOverlay
{
  if (self.no_files_view == nil)
  {
    UINib* no_files_nib = [UINib nibWithNibName:@"InfinitFilesNoFilesView" bundle:nil];
    _no_files_view = [[no_files_nib instantiateWithOwner:self options:nil] firstObject];
    [self.view addSubview:self.no_files_view];
  }
  self.search_bar.hidden = YES;
  self.no_files_view.frame = self.view.frame;
}

#pragma mark - Search Bar Delegate

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 60.0f;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.folders.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell* cell = [tableView dequeueReusableCellWithIdentifier:_file_cell_id
                                                                forIndexPath:indexPath];
  [cell configureCellWithFolder:self.folders[indexPath.row]];
  return cell;
}

#pragma mark - Table View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
  [self.search_bar resignFirstResponder];
}

- (BOOL)tableView:(UITableView*)tableView
canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
  return YES;
}

- (void)tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    [self deleteFilesAtRow:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}
- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFolderModel* folder = self.folders[indexPath.row];
  if (folder.files.count > 1)
  {
    [self performSegueWithIdentifier:@"files_multiple_segue" sender:self];
  }
  else
  {
    InfinitFolderModel* folder = self.folders[self.table_view.indexPathForSelectedRow.row];
    InfinitFilePreviewController* preview_controller =
      [InfinitFilePreviewController controllerWithFile:folder.files.firstObject];
    UINavigationController* nav_controller =
      [[UINavigationController alloc] initWithRootViewController:preview_controller];
    [self presentViewController:nav_controller animated:YES completion:nil];
  }
}

#pragma mark - Helpers

- (NSString*)pathForItem:(NSString*)item
{
  NSString* download_dir = [InfinitDirectoryManager sharedInstance].download_directory;
  return [download_dir stringByAppendingPathComponent:item];
}

- (void)deleteFilesAtRow:(NSInteger)row
{
  InfinitFolderModel* folder = self.folders[row];
  [self.folders removeObjectAtIndex:row];
  [folder deleteFolder];
  if (self.folders.count == 0)
    [self showNoFilesOverlay];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if([segue.identifier isEqualToString:@"files_multiple_segue"])
  {
    InfinitFilesMultipleViewController* view_controller =
      (InfinitFilesMultipleViewController*)segue.destinationViewController;
    view_controller.folder = self.folders[self.table_view.indexPathForSelectedRow.row];
  }
}

@end
