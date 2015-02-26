//
//  InfinitFilesViewController.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesViewController.h"

#import "InfinitColor.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFilesBottomBar.h"
#import "InfinitFilesMultipleViewController.h"
#import "InfinitFilesNavigationController.h"
#import "InfinitFilePreviewController.h"
#import "InfinitFilesTableCell.h"
#import "InfinitResizableNavigationBar.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitDirectoryManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FilesViewController");

@interface InfinitFilesViewController () <InfinitDownloadFolderManagerProtocol,
                                          UISearchBarDelegate,
                                          UITableViewDataSource,
                                          UITabBarDelegate,
                                          UITableViewDelegate>

@property (nonatomic, readonly) NSArray* all_folders;
@property (nonatomic, weak, readonly) InfinitDownloadFolderManager* download_manager;
@property (nonatomic, readonly) NSMutableArray* folder_results;
@property (nonatomic) UIView* no_files_view;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;

@property (nonatomic, weak) IBOutlet UIBarButtonItem* select_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bottom_bar_constraint;
@property (nonatomic, weak) IBOutlet UIView* bottom_view;
@property (nonatomic, strong) InfinitFilesBottomBar* bottom_bar;

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
  CGRect footer_rect = CGRectMake(0.0f, 0.0f, self.table_view.bounds.size.width, 60.0f);
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:footer_rect];
  [super viewDidLoad];
  self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
  UIGraphicsBeginImageContextWithOptions(self.search_bar.bounds.size, NO, 0.0f);
  [[InfinitColor colorWithGray:243] set];
  CGContextFillRect(UIGraphicsGetCurrentContext(), self.search_bar.bounds);
  UIImage* search_bar_bg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.search_bar.backgroundImage = search_bar_bg;
  _download_manager = [InfinitDownloadFolderManager sharedInstance];
  [self configureBottomBar];
}

- (void)configureBottomBar
{
  UINib* bottom_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitFilesBottomBar.class) bundle:nil];
  _bottom_bar = [[bottom_nib instantiateWithOwner:self options:nil] firstObject];
  [self.bottom_view addSubview:self.bottom_bar];
  NSDictionary* views = @{@"view": self.bottom_bar};
  NSArray* v_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                   options:0 
                                                                   metrics:nil 
                                                                     views:views];
  NSArray* h_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views];
  [self.bottom_view addConstraints:v_constraints];
  [self.bottom_view addConstraints:h_constraints];
  [self.bottom_bar.send_button addTarget:self
                                  action:@selector(sendTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
  [self.bottom_bar.delete_button addTarget:self
                                    action:@selector(deleteTapped:)
                          forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.table_view.indexPathForSelectedRow != nil)
    [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:YES];
  _all_folders = self.download_manager.completed_folders;
  _folder_results = [self.all_folders mutableCopy];
  self.download_manager.delegate = self;
  self.select_button.enabled = (self.all_folders.count > 0);
  InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
  [tab_controller setTabBarHidden:NO animated:YES withDelay:0.2f];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.select_button.title = NSLocalizedString(@"Select", nil);
  InfinitResizableNavigationBar* nav_bar =
    (InfinitResizableNavigationBar*)self.navigationController.navigationBar;
  if (nav_bar.large || [UIApplication sharedApplication].statusBarHidden)
  {
    [UIView animateWithDuration:(animated ? 0.3f : 0.0f)
                     animations:^
     {
       [[UIApplication sharedApplication] setStatusBarHidden:NO
                                               withAnimation:UIStatusBarAnimationSlide];
       ((InfinitResizableNavigationBar*)self.navigationController.navigationBar).large = NO;
       nav_bar.barTintColor = [UIColor whiteColor];
       [nav_bar sizeToFit];
     }];
  }
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
  [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
  for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    [self.table_view deselectRowAtIndexPath:index animated:NO];
  [super viewWillAppear:animated];
}

- (void)showNoFilesOverlay
{
  if (self.no_files_view == nil)
  {
    UINib* no_files_nib = [UINib nibWithNibName:@"InfinitFilesNoFilesView" bundle:nil];
    _no_files_view = [[no_files_nib instantiateWithOwner:self options:nil] firstObject];
    [self.view addSubview:self.no_files_view];
    NSDictionary* views = @{@"view": self.no_files_view};
    self.no_files_view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray* v_contraints =
      [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                              options:0
                                              metrics:nil
                                                views:views];
    NSArray* h_constraints =
      [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                              options:0
                                              metrics:nil
                                                views:views];
    [self.view addConstraints:v_contraints];
    [self.view addConstraints:h_constraints];
  }
  self.search_bar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.download_manager.delegate = nil;
  [super viewWillDisappear:animated];
}

#pragma mark - Search Bar Delegate

- (void)resetSearch
{
  self.search_bar.text = @"";
  _last_search_text = @"";
  _folder_results = [self.all_folders mutableCopy];
  [self.table_view reloadData];
}

- (void)searchBar:(UISearchBar*)searchBar
    textDidChange:(NSString*)searchText
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(delayedSearch:)
                                             object:_last_search_text];
  if (searchText.length == 0)
  {
    [self resetSearch];
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
didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.table_view.editing)
    self.bottom_bar.enabled = (self.table_view.indexPathsForSelectedRows.count > 0);
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.table_view.editing)
  {
    self.bottom_bar.enabled = (self.table_view.indexPathsForSelectedRows.count > 0);
    return;
  }

  InfinitFolderModel* folder = self.folder_results[indexPath.row];
  if (folder.files.count > 1)
  {
    [self performSegueWithIdentifier:@"files_multiple_segue" sender:self];
  }
  else
  {
    InfinitFolderModel* folder = self.folder_results[self.table_view.indexPathForSelectedRow.row];
    if ([self.navigationController isKindOfClass:InfinitFilesNavigationController.class])
    {
      InfinitFilesNavigationController* files_nav_controller =
      (InfinitFilesNavigationController*)self.navigationController;
      files_nav_controller.previewing = YES;
    }
    InfinitFilePreviewController* preview_controller =
      [InfinitFilePreviewController controllerWithFolder:folder andIndex:0];
    UINavigationController* nav_controller =
      [[UINavigationController alloc] initWithRootViewController:preview_controller];
    [self presentViewController:nav_controller animated:YES completion:nil];
  }
}

#pragma mark - Button Handling

- (IBAction)selectTapped:(id)sender
{
  if (self.table_view.editing)
    [self setTableEditing:NO];
  else
    [self setTableEditing:YES];
}

- (void)setTableEditing:(BOOL)editing
{
  InfinitTabBarController* main_tab_bar = (InfinitTabBarController*)self.tabBarController;
  [self.table_view setEditing:editing animated:YES];
  [main_tab_bar setTabBarHidden:editing animated:YES];
  self.bottom_bar.hidden = !editing;
  if (editing)
  {
    self.select_button.title = NSLocalizedString(@"Cancel", nil);
    self.bottom_bar_constraint.constant = 2.0f * CGRectGetHeight(self.bottom_bar.bounds);
  }
  else
  {
    self.select_button.title = NSLocalizedString(@"Select", nil);
    self.bottom_bar_constraint.constant = 0.0f;
  }
}

- (void)sendTapped:(id)sender
{
  if (!self.table_view.editing)
    return;

  self.bottom_bar_constraint.constant = 0.0f;
  self.bottom_bar.hidden = YES;
  [self performSegueWithIdentifier:@"files_to_send_segue" sender:self];
}

- (void)deleteTapped:(id)sender
{
  if (!self.table_view.editing)
    return;
  NSMutableIndexSet* set = [NSMutableIndexSet indexSet];
  for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    [set addIndex:index.row];
  NSArray* folders = [self.folder_results objectsAtIndexes:set];
  [self.folder_results removeObjectsAtIndexes:set];
  for (InfinitFolderModel* folder in folders)
    [[InfinitDownloadFolderManager sharedInstance] deleteFolder:folder];
  [self setTableEditing:NO];
  [self resetSearch];
  _all_folders = [InfinitDownloadFolderManager sharedInstance].completed_folders;
  if (self.all_folders.count == 0)
  {
    [self showNoFilesOverlay];
    self.select_button.enabled = NO;
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
  {
    [self.table_view performSelectorOnMainThread:@selector(reloadData)
                                      withObject:nil
                                   waitUntilDone:NO];
  }
  if (self.no_files_view != nil)
  {
    [self.no_files_view performSelectorOnMainThread:@selector(removeFromSuperview)
                                         withObject:nil 
                                      waitUntilDone:NO];
    self.no_files_view = nil;
    self.select_button.enabled = YES;
  }
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
  [[InfinitDownloadFolderManager sharedInstance] deleteFolder:folder];
  _all_folders = [InfinitDownloadFolderManager sharedInstance].completed_folders;
  if (self.all_folders.count == 0)
  {
    [self showNoFilesOverlay];
    self.select_button.enabled = NO;
  }
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
  else if ([segue.identifier isEqualToString:@"files_to_send_segue"])
  {
    InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
    [tab_controller setTabBarHidden:YES animated:NO];
    NSMutableIndexSet* set = [NSMutableIndexSet indexSet];
    for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
      [set addIndex:index.row];
    NSMutableArray* files = [NSMutableArray array];
    for (InfinitFolderModel* folder in [self.folder_results objectsAtIndexes:set])
      [files addObjectsFromArray:folder.file_paths];
    InfinitSendRecipientsController* send_controller =
      (InfinitSendRecipientsController*)segue.destinationViewController;
    send_controller.files = files;
    [self.table_view setEditing:NO animated:NO];
    [UIView animateWithDuration:0.3f
                     animations:^
     {
       ((InfinitResizableNavigationBar*)self.navigationController.navigationBar).large = YES;
       [[UIApplication sharedApplication] setStatusBarHidden:YES
                                               withAnimation:UIStatusBarAnimationSlide];
       self.navigationController.navigationBar.barTintColor =
       [InfinitColor colorFromPalette:InfinitPaletteColorSendBlack];
     }];
  }
}

- (void)tabIconTap
{
  if ([self.navigationController.visibleViewController isEqual:self])
    [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
  else
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
