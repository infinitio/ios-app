//
//  InfinitFilesMultipleViewController.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesMultipleViewController.h"

#import "InfinitConstants.h"
#import "InfinitFilesBottomBar.h"
#import "InfinitFilesTableCell.h"
#import "InfinitFilePreview.h"
#import "InfinitFilePreviewController.h"
#import "InfinitFilesNavigationController.h"
#import "InfinitGallery.h"
#import "InfinitResizableNavigationBar.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitColor.h>

#import <ALAssetsLibrary+CustomPhotoAlbum.h>
#import <Photos/Photos.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FilesMultipleViewController");

@interface InfinitFilesMultipleViewController () <UIGestureRecognizerDelegate,
                                                  UITableViewDataSource,
                                                  UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* back_button;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (nonatomic, weak) IBOutlet UIBarButtonItem* select_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bottom_bar_constraint;
@property (nonatomic, weak) IBOutlet UIView* bottom_view;
@property (nonatomic, strong) InfinitFilesBottomBar* bottom_bar;

@property (nonatomic, strong) ALAssetsLibrary* library;

@end

static dispatch_once_t _library_token = 0;

@implementation InfinitFilesMultipleViewController
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
  CGRect footer_rect = CGRectMake(0.0f, 0.0f, self.table_view.bounds.size.width, 60.0f);
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:footer_rect];
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;
  self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
  [super viewDidLoad];
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
  [self.bottom_bar.save_button addTarget:self
                                  action:@selector(saveTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
  [self.bottom_bar.send_button addTarget:self
                                  action:@selector(sendTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
  [self.bottom_bar.delete_button addTarget:self
                                    action:@selector(deleteTapped:)
                          forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
  _library_token = 0;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appplicationIsActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.select_button.title = NSLocalizedString(@"Select", nil);
  self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"%lu FILES", nil),
                               self.folder.files.count];
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
  [self.table_view reloadData];
  [super viewWillAppear:animated];
  [self setTableEditing:NO animated:YES];
  [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:animated];
  self.bottom_bar.save_button.hidden = ![self haveGalleryAccess];
  self.bottom_bar.save_button.enabled = NO;
}

- (void)appplicationIsActive
{
  if (self.table_view.editing)
    [self setTableEditing:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.folder.files.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_file_cell_id
                                                                      forIndexPath:indexPath];
  [cell configureCellWithFile:self.folder.files[indexPath.row]];
  return cell;
}

#pragma mark - Table View Delegate

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
    [self.folder deleteFileAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 60.0f;
}

- (void)tableView:(UITableView*)tableView
didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.table_view.editing)
  {
    self.bottom_bar.enabled = (self.table_view.indexPathsForSelectedRows.count > 0);
    for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    {
      InfinitFileModel* file = self.folder.files[index.row];
      InfinitFileTypes file_type = [InfinitFilePreview fileTypeForPath:file.path];
      if (file_type != InfinitFileTypeImage && file_type != InfinitFileTypeVideo)
      {
        self.bottom_bar.save_button.enabled = NO;
        return;
      }
    }
    self.bottom_bar.save_button.enabled = YES;
    return;
  }
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.table_view.editing)
  {
    self.bottom_bar.enabled = (self.table_view.indexPathsForSelectedRows.count > 0);
    for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    {
      InfinitFileModel* file = self.folder.files[index.row];
      InfinitFileTypes file_type = [InfinitFilePreview fileTypeForPath:file.path];
      if (file_type != InfinitFileTypeImage && file_type != InfinitFileTypeVideo)
      {
        self.bottom_bar.save_button.enabled = NO;
        return;
      }
    }
    self.bottom_bar.save_button.enabled = YES;
    return;
  }
  if ([self.navigationController isKindOfClass:InfinitFilesNavigationController.class])
  {
    InfinitFilesNavigationController* files_nav_controller =
      (InfinitFilesNavigationController*)self.navigationController;
    files_nav_controller.previewing = YES;
  }
  InfinitFilePreviewController* preview_controller =
    [InfinitFilePreviewController controllerWithFolder:self.folder andIndex:indexPath.row];
  UINavigationController* nav_controller =
    [[UINavigationController alloc] initWithRootViewController:preview_controller];
  [self presentViewController:nav_controller animated:YES completion:nil];
}

#pragma mark - Button Handling

- (IBAction)backButtonTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
  return [gestureRecognizer isKindOfClass:UIScreenEdgePanGestureRecognizer.class];
}

- (IBAction)selectTapped:(id)sender
{
  if (self.table_view.editing)
    [self setTableEditing:NO animated:YES];
  else
    [self setTableEditing:YES animated:YES];
}

- (void)setTableEditing:(BOOL)editing
               animated:(BOOL)animated
{
  InfinitTabBarController* main_tab_bar = (InfinitTabBarController*)self.tabBarController;
  [self.table_view setEditing:editing animated:animated];
  [main_tab_bar setTabBarHidden:editing animated:animated];
  self.bottom_bar.hidden = !editing;
  self.back_button.enabled = !editing;
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

- (void)saveTapped:(id)sender
{
  [((InfinitTabBarController*)self.tabBarController) showCopyToGalleryNotification];
  NSMutableArray* paths = [NSMutableArray array];
  for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
  {
    [paths addObject:self.folder.file_paths[index.row]];
  }
  [InfinitGallery saveToGallery:paths];
  [self setTableEditing:NO animated:YES];
}

- (void)sendTapped:(id)sender
{
  if (!self.table_view.editing)
    return;

  self.bottom_bar_constraint.constant = 0.0f;
  self.bottom_bar.hidden = YES;
  [self performSegueWithIdentifier:@"files_multi_to_send" sender:self];
}

- (void)deleteTapped:(id)sender
{
  [self.table_view beginUpdates];
  for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
    [self.folder deleteFileAtIndex:index.row];
  [self.table_view deleteRowsAtIndexPaths:self.table_view.indexPathsForSelectedRows
                   withRowAnimation:UITableViewRowAnimationAutomatic];
  [self.table_view endUpdates];
  [self setTableEditing:NO animated:YES];
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"files_multi_to_send"])
  {
    InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
    [tab_controller setTabBarHidden:YES animated:NO];
    NSMutableIndexSet* set = [NSMutableIndexSet indexSet];
    for (NSIndexPath* index in self.table_view.indexPathsForSelectedRows)
      [set addIndex:index.row];
    NSMutableArray* files = [NSMutableArray array];
    for (InfinitFileModel* file in [self.folder.files objectsAtIndexes:set])
      [files addObject:file.path];
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

#pragma mark - Helpers

- (ALAssetsLibrary*)library
{
  dispatch_once(&_library_token, ^
  {
    _library = [[ALAssetsLibrary alloc] init];
  });
  return _library;
}

- (BOOL)haveGalleryAccess
{
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)
    return YES;
  return NO;
}

@end
