//
//  InfinitFilesViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesViewController_iPad.h"

#import "InfinitConstants.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFilesEmptyOverlay_iPad.h"
#import "InfinitFilePreviewController.h"
#import "InfinitFilesCollectionViewController_iPad.h"
#import "InfinitFilesFolderViewController_iPad.h"
#import "InfinitFilesSearchPopover_iPad.h"
#import "InfinitFilesTableViewController_iPad.h"
#import "InfinitGalleryManager.h"
#import "InfinitHostDevice.h"
#import "InfinitMainSplitViewController_iPad.h"
#import "InfinitMetricsManager.h"
#import "InfinitStatusBarNotifier.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

@interface InfinitFilesViewController_iPad () <InfinitDownloadFolderManagerProtocol,
                                               InfinitFilesDisplayProtocol,
                                               InfinitFilesSearchProtocol,
                                               UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) IBOutlet UISegmentedControl* segmented_control;
@property (nonatomic, weak) IBOutlet UIButton* right_button_inner;
@property (nonatomic, weak) IBOutlet UIButton* right_button_outer;
@property (nonatomic, weak) IBOutlet UIView* main_view;
@property (nonatomic, weak) IBOutlet UIButton* left_button_center;
@property (nonatomic, weak) IBOutlet UIButton* left_button_inner;
@property (nonatomic, weak) IBOutlet UIButton* left_button_outer;
@property (nonatomic, weak) IBOutlet UIButton* send_button;

@property (nonatomic, readonly) NSMutableArray* all_folders;
@property (atomic, readonly) BOOL editing;
@property (nonatomic, readonly) NSString* last_search_string;

@property (nonatomic, weak) InfinitFilesDisplayController_iPad* current_controller;
@property (nonatomic, strong) InfinitFilesEmptyOverlay_iPad* empty_view;
@property (nonatomic, strong) InfinitFilesCollectionViewController_iPad* collection_view_controller;
@property (nonatomic, strong) InfinitFilesFolderViewController_iPad* folder_view_controller;
@property (nonatomic, strong) UIPopoverController* search_popover_controller;
@property (nonatomic, strong) InfinitFilesSearchPopover_iPad* search_view_controller;
@property (nonatomic, strong) InfinitFilesTableViewController_iPad* table_view_controller;

@property (nonatomic, strong) UIView* send_onboarding_view;
@property (nonatomic, strong) UIView* receive_onboarding_view;
@property (nonatomic, readonly) BOOL show_onboarding;

@end

typedef NS_ENUM(NSUInteger, InfinitFilesFilter)
{
  InfinitFilesFilterAll = 0,
  InfinitFilesFilterPhotos,
  InfinitFilesFilterVideos,
  InfinitFilesFilterDocs,
  InfinitFilesFilterMusic,
  InfinitFilesFilterOther,
};

static dispatch_once_t _first_appear = 0;

@implementation InfinitFilesViewController_iPad

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.main_view.clipsToBounds = YES;
  UINib* search_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesSearchPopover_iPad.class)
                                     bundle:nil];
  _search_view_controller = [[search_nib instantiateWithOwner:self options:nil] firstObject];
  self.search_view_controller.delegate = self;
  self.send_button.layer.shadowColor = [UIColor blackColor].CGColor;
  self.send_button.layer.shadowOpacity = 0.15f;
  self.send_button.layer.shadowRadius = 2.0f;
  self.send_button.layer.shadowOffset = CGSizeZero;
  self.send_button.layer.masksToBounds = NO;
  CGSize image_size = self.send_button.imageView.image.size;
  CGRect shadow_rect = CGRectMake(0.0f, 0.0f, image_size.width, image_size.height);
  self.send_button.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:shadow_rect].CGPath;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  _all_folders = [[InfinitDownloadFolderManager sharedInstance].completed_folders mutableCopy];
  [InfinitDownloadFolderManager sharedInstance].delegate = self;
  dispatch_once(&_first_appear, ^
  {
    [self switchToViewController:self.table_view_controller];
  });
  if (self.current_controller == nil)
    [self switchToViewController:self.table_view_controller];
  if (self.all_folders.count == 0)
    [self showEmptyFilesView];
  else
    [self removeEmptyFilesView];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  NSArray* transactions = [manager transactionsIncludingArchived:YES
                                                  thisDeviceOnly:YES 
                                               excludeReceivable:YES];
  if (transactions.count == 0)
    _show_onboarding = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [InfinitDownloadFolderManager sharedInstance].delegate = nil;
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION 
                                                object:nil];
}

- (IBAction)screenTapped:(id)sender
{
  if (self.search_popover_controller.isPopoverVisible)
  {
    [self.search_popover_controller dismissPopoverAnimated:YES];
    self.search_view_controller.search_string = nil;
  }
}

- (void)showEmptyFilesView
{
  self.segmented_control.hidden = YES;
  self.left_button_outer.enabled = NO;
  self.right_button_inner.enabled = NO;
  self.right_button_outer.enabled = NO;
  [self.main_view insertSubview:self.empty_view belowSubview:self.send_button];
  NSDictionary* views = @{@"view": self.empty_view};
  NSMutableArray* constraints =
    [NSMutableArray arrayWithArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views]];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views]];
  [self.main_view addConstraints:constraints];
}

- (void)removeEmptyFilesView
{
  self.segmented_control.hidden = NO;
  self.left_button_outer.enabled = YES;
  self.right_button_inner.enabled = YES;
  self.right_button_outer.enabled = YES;
  [self.empty_view removeFromSuperview];
}

#pragma mark - Download Folder Delegate

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
                  addedFolder:(InfinitFolderModel*)folder
{}

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
               folderFinished:(InfinitFolderModel*)folder
{
  @synchronized(self.all_folders)
  {
    if ([self.all_folders containsObject:folder])
      return;
    [self.all_folders insertObject:folder atIndex:0];
    [self.current_controller folderAdded:folder];
    if (self.all_folders.count > 0)
      [self removeEmptyFilesView];
  }
}

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
                deletedFolder:(InfinitFolderModel*)folder
{
  @synchronized(self.all_folders)
  {
    if (![self.all_folders containsObject:folder])
      return;
    [self.all_folders removeObject:folder];
    [self.current_controller folderRemoved:folder];
    if (self.all_folders.count == 0)
      [self showEmptyFilesView];
  }
}

#pragma mark - Button Handling

- (IBAction)leftOuterTapped:(id)sender
{
  if (self.editing) // Send
  {
    NSArray* items = self.current_controller.current_selection;
    NSMutableArray* paths = [NSMutableArray array];
    for (id item in items)
    {
      if ([item isKindOfClass:InfinitFolderModel.class])
      {
        InfinitFolderModel* folder = (InfinitFolderModel*)item;
        [paths addObjectsFromArray:folder.file_paths];
      }
      else if ([item isKindOfClass:InfinitFileModel.class])
      {
        InfinitFileModel* file = (InfinitFileModel*)item;
        [paths addObject:file.path];
      }
    }
    InfinitTemporaryFileManager* manager = [InfinitTemporaryFileManager sharedInstance];
    InfinitManagedFiles* managed_files = [manager createManagedFiles];
    [manager addFiles:paths toManagedFiles:managed_files];
    [((InfinitMainSplitViewController_iPad*)self.splitViewController) showSendViewForManagedFiles:managed_files];
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewOpen
                               method:InfinitUIMethodFiles];
    self.editing = NO;
  }
  else // Back
  {
    UIImage* left_outer_image = nil;
    if (self.current_controller == self.folder_view_controller)
    {
      [self switchToViewController:self.table_view_controller animate:YES reverse:YES];
      left_outer_image = [UIImage imageNamed:@"icon-grid"];
      [self.left_button_outer setTitle:nil forState:UIControlStateNormal];
    }
    else
    {
      if (self.current_controller == self.table_view_controller)
      {
        [self switchToViewController:self.collection_view_controller];
        left_outer_image = [UIImage imageNamed:@"icon-list"];
      }
      else
      {
        [self switchToViewController:self.table_view_controller];
        left_outer_image = [UIImage imageNamed:@"icon-grid"];
      }
    }
    [self.left_button_outer setImage:left_outer_image forState:UIControlStateNormal];
  }
}

- (IBAction)leftCenterTapped:(id)sender
{
  if (self.editing)
  {
    NSArray* items = self.current_controller.current_selection;
    if (items.count == 0)
      return;
    NSMutableArray* paths = [NSMutableArray array];
    if ([items[0] isKindOfClass:InfinitFolderModel.class])
    {
      for (InfinitFolderModel* folder in items)
      {
        [paths addObjectsFromArray:folder.file_paths];
      }
    }
    else if ([items[0] isKindOfClass:InfinitFileModel.class])
    {
      for (InfinitFileModel* file in items)
        [paths addObject:file.path];
    }
    [InfinitGalleryManager saveToGallery:paths];
    NSString* message = NSLocalizedString(@"Saving to gallery...", nil);
    [[InfinitStatusBarNotifier sharedInstance] showMessage:message
                                                    ofType:InfinitStatusBarNotificationInfo
                                                  duration:4.0f];
    self.editing = NO;
  }
}

- (IBAction)leftInnerTapped:(id)sender
{
  if (self.editing)
  {
    NSArray* items = self.current_controller.current_selection;
    if (items.count == 0)
      return;
    NSMutableArray* paths = [NSMutableArray array];
    if ([items[0] isKindOfClass:InfinitFolderModel.class])
    {
      for (InfinitFolderModel* folder in items)
      {
        for (NSString* path in folder.file_paths)
          [paths addObject:[NSURL fileURLWithPath:path]];
      }
    }
    else if ([items[0] isKindOfClass:InfinitFileModel.class])
    {
      for (InfinitFileModel* file in items)
        [paths addObject:[NSURL fileURLWithPath:file.path]];
    }
    UIActivityViewController* activity_controller =
      [[UIActivityViewController alloc] initWithActivityItems:paths applicationActivities:nil];
    if ([activity_controller respondsToSelector:@selector(popoverPresentationController)])
    {
      activity_controller.popoverPresentationController.sourceView = self.left_button_inner;
      activity_controller.popoverPresentationController.sourceRect = self.left_button_inner.bounds;
      activity_controller.popoverPresentationController.delegate = self;
    }
    [self presentViewController:activity_controller animated:YES completion:^
     {
       self.editing = NO;
     }];
  }
}

- (IBAction)rightInnerTapped:(id)sender
{
  if (self.editing)
  {
    NSArray* items = self.current_controller.current_selection;
    if (items.count == 0)
      return;
    if ([items[0] isKindOfClass:InfinitFolderModel.class])
    {
      for (InfinitFolderModel* folder in items)
        [[InfinitDownloadFolderManager sharedInstance] deleteFolder:folder];
    }
    else if ([items[0] isKindOfClass:InfinitFileModel.class])
    {
      for (InfinitFileModel* file in items)
        [file.folder deleteFileAtIndex:[file.folder.files indexOfObject:file]];
      [self.current_controller filesDeleted];
    }
    self.editing = NO;
  }
  else
  {
    if (self.search_popover_controller == nil)
    {
      _search_popover_controller =
        [[UIPopoverController alloc] initWithContentViewController:self.search_view_controller];
    }
    if (self.search_popover_controller.isPopoverVisible)
      return;
    [self.search_popover_controller presentPopoverFromRect:self.right_button_inner.frame
                                                    inView:self.view 
                                  permittedArrowDirections:UIPopoverArrowDirectionUp
                                                  animated:YES];
  }
}

- (IBAction)rightOuterTapped:(id)sender
{
  self.editing = !self.editing;
}

- (IBAction)segmentedControlChanged:(id)sender
{
  self.current_controller.filter = [self currentFilter];
}

- (void)setEditing:(BOOL)editing
{
  if (self.editing == editing)
    return;
  _editing = editing;
  self.current_controller.editing = self.editing;
  self.left_button_center.hidden = !self.editing;
  self.left_button_inner.hidden = !self.editing;
  UIImage* left_outer_image = nil;
  UIImage* right_inner_image = nil;
  NSString* back_text = nil;
  NSString* select_text = nil;
  if (self.editing)
  {
    left_outer_image = [UIImage imageNamed:@"icon-send-red"];
    select_text = NSLocalizedString(@"Cancel", nil);
    right_inner_image = [UIImage imageNamed:@"icon-delete-red"];
  }
  else
  {
    if (self.current_controller == self.folder_view_controller)
      back_text = NSLocalizedString(@"Back", nil);
    else if (self.current_controller == self.table_view_controller)
      left_outer_image = [UIImage imageNamed:@"icon-grid"];
    else if (self.current_controller == self.collection_view_controller)
      left_outer_image = [UIImage imageNamed:@"icon-list"];
    select_text = NSLocalizedString(@"Select", nil);
    right_inner_image = [UIImage imageNamed:@"icon-search"];
  }
  [self.right_button_outer setTitle:select_text forState:UIControlStateNormal];
  [self.left_button_outer setImage:left_outer_image forState:UIControlStateNormal];
  [self.left_button_outer setTitle:back_text forState:UIControlStateNormal];
  [self.right_button_inner setImage:right_inner_image forState:UIControlStateNormal];
  if (!self.editing)
    self.send_button.enabled = YES;
  [UIView animateWithDuration:0.3f animations:^
  {
    self.send_button.alpha = self.editing ? 0.0f : 1.0f;
  } completion:^(BOOL finished)
  {
    self.send_button.enabled = !self.editing;
  }];
}

- (InfinitFileTypes)currentFilter
{
  InfinitFileTypes filter = InfinitFileTypeAll;
  switch (self.segmented_control.selectedSegmentIndex)
  {
    case InfinitFilesFilterAll:
      filter = InfinitFileTypeAll;
      break;
    case InfinitFilesFilterPhotos:
      filter = InfinitFileTypeImage;
      break;
    case InfinitFilesFilterVideos:
      filter = InfinitFileTypeVideo;
      break;
    case InfinitFilesFilterDocs:
      filter = (InfinitFileTypeDocument | InfinitFileTypePresentation | InfinitFileTypeSpreadsheet);
      break;
    case InfinitFilesFilterMusic:
      filter = InfinitFileTypeAudio;
      break;

    case InfinitFilesFilterOther:
      filter = ~(InfinitFileTypeDocument |
                 InfinitFileTypePresentation |
                 InfinitFileTypeSpreadsheet |
                 InfinitFileTypeAudio |
                 InfinitFileTypeVideo |
                 InfinitFileTypeImage);
    default:
      break;
  }
  return filter;
}

- (IBAction)sendButtonTapped:(id)sender
{
  [((InfinitMainSplitViewController_iPad*)self.splitViewController) showSendGalleryView];
}

#pragma mark - Files Display Delegate

- (void)actionForFile:(InfinitFileModel*)file
               sender:(InfinitFilesDisplayController_iPad*)sender
{
  InfinitFilePreviewController* preview_controller =
    [InfinitFilePreviewController controllerWithFolder:file.folder
                                              andIndex:[file.folder.files indexOfObject:file]];
  UINavigationController* nav_controller =
    [[UINavigationController alloc] initWithRootViewController:preview_controller];
  [self presentViewController:nav_controller animated:YES completion:nil];
}

- (void)actionForFolder:(InfinitFolderModel*)folder
                 sender:(InfinitFilesDisplayController_iPad*)sender
{
  if (folder.files.count == 1)
  {
    InfinitFilePreviewController* preview_controller =
      [InfinitFilePreviewController controllerWithFolder:folder andIndex:0];
    UINavigationController* nav_controller =
      [[UINavigationController alloc] initWithRootViewController:preview_controller];
    [self presentViewController:nav_controller animated:YES completion:nil];
  }
  else
  {
    self.folder_view_controller.folder = folder;
    [self switchToViewController:self.folder_view_controller animate:YES reverse:NO];
    [self.left_button_outer setImage:nil forState:UIControlStateNormal];
    [self.left_button_outer setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
  }
}

- (void)deleteFile:(InfinitFileModel*)file
            sender:(InfinitFilesDisplayController_iPad*)sender
{
  InfinitFolderModel* folder = file.folder;
  [folder deleteFileAtIndex:[folder.files indexOfObject:file]];
  [self.current_controller filesDeleted];
}

- (void)deleteFolder:(InfinitFolderModel*)folder
              sender:(InfinitFilesDisplayController_iPad*)sender
{
  [[InfinitDownloadFolderManager sharedInstance] deleteFolder:folder];
}

#pragma mark - Search Delegate

- (void)searchView:(InfinitFilesSearchPopover_iPad*)sender
   stringDidChange:(NSString*)string
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(delayedSearch:)
                                             object:self.last_search_string];
  [self performSelector:@selector(delayedSearch:) withObject:string afterDelay:0.2f];
  _last_search_string = string;
}

- (void)delayedSearch:(NSString*)string
{
  self.current_controller.search_string = string;
}

#pragma mark - Public

- (void)showFolder:(InfinitFolderModel*)folder
{
  if (self.current_controller == self.folder_view_controller)
  {
    self.folder_view_controller.folder = folder;
    [self.folder_view_controller reload];
  }
  else
  {
    self.folder_view_controller.folder = folder;
    [self switchToViewController:self.folder_view_controller animate:YES reverse:NO];
    [self.left_button_outer setImage:nil forState:UIControlStateNormal];
    [self.left_button_outer setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
  }
}

- (void)hideReceiveOnboarding
{
  if (self.receive_onboarding_view == nil)
    return;
  [self.receive_onboarding_view removeFromSuperview];
  _receive_onboarding_view = nil;
}

- (void)showReceiveOnboarding
{
  if (self.receive_onboarding_view == nil)
  {
    UINib* nib = [UINib nibWithNibName:@"InfinitFilesViewOnboarding_iPad" bundle:nil];
    _receive_onboarding_view = [nib instantiateWithOwner:self options:nil].firstObject;
  }
  if (self.current_controller == self.table_view_controller)
  {
    CGRect frame = [self.view convertRect:self.table_view_controller.last_row_rect
                                 fromView:self.table_view_controller.view];
    [self.view addSubview:self.receive_onboarding_view];
    self.receive_onboarding_view.frame =
      CGRectMake(frame.origin.x + floor(frame.size.width / 2.0f) - 75.0f,
                 frame.origin.y + frame.size.height + 10.0f,
                 self.receive_onboarding_view.bounds.size.width,
                 self.receive_onboarding_view.bounds.size.height);
  }
}

- (void)hideSendOnboarding
{
  if (self.send_onboarding_view == nil)
    return;
  [self.send_onboarding_view removeFromSuperview];
  _send_onboarding_view = nil;
}

- (void)showSendOnboarding
{
  if (self.send_onboarding_view)
    return;

  UINib* nib = [UINib nibWithNibName:@"InfinitSendButtonOboarding_iPad" bundle:nil];
  _send_onboarding_view = [nib instantiateWithOwner:self options:nil].firstObject;
  self.send_onboarding_view.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.send_onboarding_view];
  NSLayoutConstraint* x_constraint =
    [NSLayoutConstraint constraintWithItem:self.send_button
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.send_onboarding_view
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0f
                                  constant:0.0f];
  NSLayoutConstraint* y_constraint =
    [NSLayoutConstraint constraintWithItem:self.send_button
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.send_onboarding_view
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0f
                                  constant:0.0f];
  [self.view addConstraints:@[x_constraint, y_constraint]];
}

#pragma mark - Helpers

- (void)switchToViewController:(InfinitFilesDisplayController_iPad*)new_controller
{
  [self switchToViewController:new_controller animate:NO reverse:NO];
}

- (void)switchToViewController:(InfinitFilesDisplayController_iPad*)new_controller
                       animate:(BOOL)animate
                       reverse:(BOOL)reverse
{
  if (self.current_controller == new_controller)
    return;
  if (new_controller != self.table_view_controller)
    [self hideReceiveOnboarding];
  InfinitFilesDisplayController_iPad* old_controller = self.current_controller;
  self.search_view_controller.search_string = nil;
  new_controller.all_folders = [self.all_folders copy];
  new_controller.filter = [self currentFilter];
  new_controller.search_string = self.search_view_controller.search_string;
  new_controller.view.frame = self.main_view.bounds;
  if (old_controller == nil)
    [self.main_view insertSubview:new_controller.view belowSubview:self.send_button];
  else
    [self.main_view insertSubview:new_controller.view belowSubview:old_controller.view];
  [self addChildViewController:new_controller];
  CGFloat width = self.main_view.bounds.size.width;
  if (animate)
    new_controller.view.transform = CGAffineTransformMakeTranslation(reverse ? -width : width, 0.0f);
  [new_controller didMoveToParentViewController:self];
  [UIView animateWithDuration:animate ? 0.3f : 0.0f
                   animations:^
  {
    if (animate)
    {
      new_controller.view.transform = CGAffineTransformIdentity;
      old_controller.view.transform =
        CGAffineTransformMakeTranslation(reverse ? width : -width, 0.0f);
    }
  } completion:^(BOOL finished)
  {
    if (old_controller)
    {
      [old_controller willMoveToParentViewController:nil];
      [old_controller.view removeFromSuperview];
      [old_controller removeFromParentViewController];
      new_controller.view.transform = CGAffineTransformIdentity;
      old_controller.view.transform = CGAffineTransformIdentity;
    }
    _current_controller = new_controller;
    if (self.show_onboarding)
    {
      if (new_controller == self.table_view_controller)
        [self showReceiveOnboarding];
      [self showSendOnboarding];
    }
  }];
}

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

- (InfinitFilesEmptyOverlay_iPad*)empty_view
{
  if (_empty_view == nil)
  {
    UINib* nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesEmptyOverlay_iPad.class)
                                bundle:nil];
    _empty_view = [nib instantiateWithOwner:self options:nil].firstObject;
    _empty_view.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _empty_view;
}

- (InfinitFilesFolderViewController_iPad*)folder_view_controller
{
  if (_folder_view_controller == nil)
  {
    _folder_view_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"single_folder_table_view_ipad"];
    self.folder_view_controller.delegate = self;
  }
  return _folder_view_controller;
}

- (InfinitFilesCollectionViewController_iPad*)collection_view_controller
{
  if (_collection_view_controller == nil)
  {
    _collection_view_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"files_collection_view_ipad"];
    self.collection_view_controller.delegate = self;
  }
  return _collection_view_controller;
}

- (InfinitFilesTableViewController_iPad*)table_view_controller
{
  if (_table_view_controller == nil)
  {
    _table_view_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"files_table_view_ipad"];
    self.table_view_controller.delegate = self;
  }
  return _table_view_controller;
}


- (void)transactionUpdated:(NSNotification*)notification
{
  if (self.show_onboarding)
  {
    NSUInteger count =
      [[InfinitPeerTransactionManager sharedInstance] transactionsIncludingArchived:YES
                                                                     thisDeviceOnly:YES
                                                                  excludeReceivable:YES].count;
    _show_onboarding = (count == 0);
  }
  if (!self.show_onboarding)
  {
    [self hideReceiveOnboarding];
    [self hideSendOnboarding];
  }
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController*)popoverPresentationController
{
  self.editing = NO;
  return YES;
}

@end
