//
//  InfinitFilesViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesViewController_iPad.h"

#import "InfinitDownloadFolderManager.h"
#import "InfinitFilesCollectionViewController_iPad.h"
#import "InfinitFilesFolderViewController_iPad.h"
#import "InfinitFilePreviewController.h"
#import "InfinitFilesTableViewController_iPad.h"

@interface InfinitFilesViewController_iPad () <InfinitDownloadFolderManagerProtocol,
                                               InfinitFilesDisplayProtocol>

@property (nonatomic, weak) IBOutlet UISegmentedControl* segmented_control;
@property (nonatomic, weak) IBOutlet UIButton* right_button_inner;
@property (nonatomic, weak) IBOutlet UIButton* right_button_outer;
@property (nonatomic, weak) IBOutlet UIView* main_view;
@property (nonatomic, weak) IBOutlet UIButton* left_button_inner;
@property (nonatomic, weak) IBOutlet UIButton* left_button_outer;

@property (nonatomic, readonly) NSMutableArray* all_folders;
@property (nonatomic, weak) InfinitFilesDisplayController_iPad* current_controller;
@property (nonatomic, strong) InfinitFilesCollectionViewController_iPad* collection_view_controller;
@property (nonatomic, strong) InfinitFilesFolderViewController_iPad* folder_view_controller;
@property (nonatomic, strong) InfinitFilesTableViewController_iPad* table_view_controller;

@end

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
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  _all_folders = [[InfinitDownloadFolderManager sharedInstance].completed_folders mutableCopy];
  [self switchToViewController:self.table_view_controller];
  [InfinitDownloadFolderManager sharedInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [InfinitDownloadFolderManager sharedInstance].delegate = nil;
  [super viewWillDisappear:animated];
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
  if (self.current_controller == self.folder_view_controller)
  {
    [self switchToViewController:self.table_view_controller animate:YES reverse:YES];
  }
  else
  {
    if (self.current_controller == self.table_view_controller)
      [self switchToViewController:self.collection_view_controller];
    else
      [self switchToViewController:self.table_view_controller];
  }
}

- (IBAction)leftInnerTapped:(id)sender
{

}

- (IBAction)rightInnerTapped:(id)sender
{

}

- (IBAction)rightOuterTapped:(id)sender
{
  self.current_controller.editing = !self.current_controller.editing;
}

- (IBAction)segmentedControlChanged:(id)sender
{
  
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
  }
}

- (void)deleteFile:(InfinitFileModel*)file
            sender:(InfinitFilesDisplayController_iPad*)sender
{

}

- (void)deleteFolder:(InfinitFolderModel*)folder
              sender:(InfinitFilesDisplayController_iPad*)sender
{

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
  new_controller.all_folders = [self.all_folders copy];
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
