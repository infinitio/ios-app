//
//  InfinitFilesViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesViewController_iPad.h"

#import "InfinitDownloadFolderManager.h"
#import "InfinitFilePreviewController.h"
#import "InfinitFilesCollectionViewController_iPad.h"
#import "InfinitFilesFolderViewController_iPad.h"
#import "InfinitFilesSearchPopover_iPad.h"
#import "InfinitFilesTableViewController_iPad.h"

@interface InfinitFilesViewController_iPad () <InfinitDownloadFolderManagerProtocol,
                                               InfinitFilesDisplayProtocol,
                                               InfinitFilesSearchProtocol>

@property (nonatomic, weak) IBOutlet UISegmentedControl* segmented_control;
@property (nonatomic, weak) IBOutlet UIButton* right_button_inner;
@property (nonatomic, weak) IBOutlet UIButton* right_button_outer;
@property (nonatomic, weak) IBOutlet UIView* main_view;
@property (nonatomic, weak) IBOutlet UIButton* left_button_inner;
@property (nonatomic, weak) IBOutlet UIButton* left_button_outer;

@property (nonatomic, readonly) NSMutableArray* all_folders;
@property (atomic, readonly) BOOL editing;
@property (nonatomic, readonly) NSString* last_search_string;

@property (nonatomic, weak) InfinitFilesDisplayController_iPad* current_controller;
@property (nonatomic, strong) InfinitFilesCollectionViewController_iPad* collection_view_controller;
@property (nonatomic, strong) InfinitFilesFolderViewController_iPad* folder_view_controller;
@property (nonatomic, strong) UIPopoverController* search_popover_controller;
@property (nonatomic, strong) InfinitFilesSearchPopover_iPad* search_view_controller;
@property (nonatomic, strong) InfinitFilesTableViewController_iPad* table_view_controller;

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

@implementation InfinitFilesViewController_iPad

- (void)viewDidLoad
{
  [super viewDidLoad];
  _collection_view_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"files_collection_view_ipad"];
  self.collection_view_controller.delegate = self;
  _folder_view_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"single_folder_table_view_ipad"];
  self.folder_view_controller.delegate = self;
  _table_view_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"files_table_view_ipad"];
  self.table_view_controller.delegate = self;
  self.main_view.clipsToBounds = YES;
  UINib* search_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesSearchPopover_iPad.class)
                                     bundle:nil];
  _search_view_controller = [[search_nib instantiateWithOwner:self options:nil] firstObject];
  self.search_view_controller.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  static dispatch_once_t first_appear = 0;
  dispatch_once(&first_appear, ^
  {
    _all_folders = [[InfinitDownloadFolderManager sharedInstance].completed_folders mutableCopy];
    [self switchToViewController:self.table_view_controller];
  });
  [InfinitDownloadFolderManager sharedInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [InfinitDownloadFolderManager sharedInstance].delegate = nil;
  [super viewWillDisappear:animated];
}

- (IBAction)screenTapped:(id)sender
{
  if (self.search_popover_controller.isPopoverVisible)
  {
    [self.search_popover_controller dismissPopoverAnimated:YES];
    self.search_view_controller.search_string = nil;
  }
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
  }
}

#pragma mark - Button Handling

- (IBAction)leftOuterTapped:(id)sender
{
  if (self.editing)
  {
    // XXX send
    self.editing = NO;
  }
  else
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

- (IBAction)leftInnerTapped:(id)sender
{
  if (self.editing)
  {
    // XXX save to gallery
    self.editing = NO;
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
  __weak InfinitFilesDisplayController_iPad* old_controller = self.current_controller;
  self.search_view_controller.search_string = nil;
  new_controller.all_folders = [self.all_folders copy];
  new_controller.filter = [self currentFilter];
  new_controller.search_string = self.search_view_controller.search_string;
  new_controller.view.frame = self.main_view.bounds;
  if (old_controller == nil)
    [self.main_view addSubview:new_controller.view];
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
  }];
}

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

@end
