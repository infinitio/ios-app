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
#import "InfinitDownloadFolderManager.h"

#import <Gap/InfinitDirectoryManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FilesViewController");

@interface InfinitFilesViewController () <InfinitDownloadFolderManagerProtocol,
                                          UISearchBarDelegate,
                                          UITableViewDataSource,
                                          UITableViewDelegate>

@property (nonatomic, readonly) NSArray* all_folders;
@property (nonatomic, weak, readonly) InfinitDownloadFolderManager* download_manager;
@property (nonatomic, readonly) NSMutableArray* folder_results;
@property (nonatomic) UIView* no_files_view;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;

@end

@implementation InfinitFilesViewController
{
@private
  NSString* _file_cell_id;
  NSString* _last_search_text;
  NSArray* _last_contents;
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
  UIGraphicsBeginImageContextWithOptions(self.search_bar.bounds.size, NO, 0.0f);
  [[InfinitColor colorWithGray:240] set];
  CGContextFillRect(UIGraphicsGetCurrentContext(), self.search_bar.bounds);
  UIImage* search_bar_bg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.search_bar.backgroundImage = search_bar_bg;
  _download_manager = [InfinitDownloadFolderManager sharedInstance];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.table_view.indexPathForSelectedRow != nil)
    [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:YES];
  _all_folders = [InfinitDownloadFolderManager sharedInstance].completed_folders;
  _folder_results = [self.all_folders mutableCopy];
  self.download_manager.delegate = self;
  if (self.all_folders.count == 0)
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
    if (_last_search_text.length == 0)
      [self.table_view reloadData];
    else
      [self delayedSearch:_last_search_text];
  }
  [super viewWillAppear:animated];
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

- (void)viewWillDisappear:(BOOL)animated
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.download_manager.delegate = nil;
  [super viewWillDisappear:animated];
}

#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar*)searchBar
    textDidChange:(NSString*)searchText
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(delayedSearch:)
                                             object:_last_search_text];
  if (searchText.length == 0)
  {
    _folder_results = [self.all_folders mutableCopy];
    [self.table_view reloadData];
  }
  [self performSelector:@selector(delayedSearch:) withObject:searchText afterDelay:0.2f];
  _last_search_text = searchText;
}

- (void)delayedSearch:(NSString*)search_text
{
  if (search_text.length == 0)
    return;
  [self.folder_results removeAllObjects];
  for (InfinitFolderModel* folder in self.all_folders)
  {
    if ([folder containsString:search_text])
      [self.folder_results addObject:folder];
  }
  [self.table_view reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
  [searchBar resignFirstResponder];
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 60.0f;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.folder_results.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell* cell = [tableView dequeueReusableCellWithIdentifier:_file_cell_id
                                                                forIndexPath:indexPath];
  [cell configureCellWithFolder:self.folder_results[indexPath.row]];
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
  InfinitFolderModel* folder = self.folder_results[indexPath.row];
  if (folder.files.count > 1)
  {
    [self performSegueWithIdentifier:@"files_multiple_segue" sender:self];
  }
  else
  {
    InfinitFolderModel* folder = self.folder_results[self.table_view.indexPathForSelectedRow.row];
    InfinitFilePreviewController* preview_controller =
      [InfinitFilePreviewController controllerWithFolder:folder andIndex:0];
    UINavigationController* nav_controller =
      [[UINavigationController alloc] initWithRootViewController:preview_controller];
    [self presentViewController:nav_controller animated:YES completion:nil];
  }
}

#pragma mark - Download Folder Manager Protocol

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
                  addedFolder:(InfinitFolderModel*)folder
{}

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
               folderFinished:(InfinitFolderModel*)folder
{
  _all_folders = self.download_manager.completed_folders;
  if (self.search_bar.text.length == 0)
    [self.table_view reloadData];
}

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
                deletedFolder:(InfinitFolderModel*)folder
{
  _all_folders = self.download_manager.completed_folders;
  if ([self.folder_results containsObject:folder])
  {
    NSIndexPath* index = [NSIndexPath indexPathForRow:[self.folder_results indexOfObject:folder] 
                                            inSection:0];
    [self.folder_results removeObject:folder];
    [self.table_view deleteRowsAtIndexPaths:@[index]
                           withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Helpers

- (void)deleteFilesAtRow:(NSInteger)row
{
  InfinitFolderModel* folder = self.folder_results[row];
  [self.folder_results removeObjectAtIndex:row];
  [folder deleteFolder];
  if (self.folder_results.count == 0)
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
    view_controller.folder = self.folder_results[self.table_view.indexPathForSelectedRow.row];
  }
}

@end
