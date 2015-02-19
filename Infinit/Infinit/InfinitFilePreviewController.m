//
//  InfinitFilePreviewController.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilePreviewController.h"

#import "InfinitColor.h"
#import "InfinitFileModel.h"
#import "InfinitFilePreview.h"

#import "JDStatusBarNotification.h"

#import <Gap/InfinitConnectionManager.h>

@interface InfinitFilePreviewController () <QLPreviewControllerDataSource,
                                            QLPreviewControllerDelegate>

@property (nonatomic, weak, readwrite) InfinitFolderModel* folder;

@end

@implementation InfinitFilePreviewController

- (UIViewController*)presentingViewController
{
  return nil;
}

#pragma mark - Init

+ (instancetype)controllerWithFolder:(InfinitFolderModel*)folder
                            andIndex:(NSInteger)index
{
  InfinitFilePreviewController* res = [[InfinitFilePreviewController alloc] init];
  [res configureWithFolder:folder andIndex:index];
  return res;
}

- (void)configureWithFolder:(InfinitFolderModel*)folder
                   andIndex:(NSInteger)index
{
  self.folder = folder;
  self.currentPreviewItemIndex = index;
  self.delegate = self;
  self.dataSource = self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = self.folder.name;
  UIImage* back_image = [UIImage imageNamed:@"icon-arrow-down-red"];
  UIBarButtonItem* back_button = [[UIBarButtonItem alloc] initWithImage:back_image
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self 
                                                                 action:@selector(backTapped:)];
  self.navigationItem.leftBarButtonItem = back_button;
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.navigationController.navigationBar.tintColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  self.navigationController.toolbar.tintColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
}

- (void)viewDidAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
  [JDStatusBarNotification dismiss];
  [super viewDidAppear:animated];
}

- (void)backTapped:(id)sender
{
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation Controller Delegate

- (BOOL)hidesBottomBarWhenPushed
{
  return YES;
}

#pragma mark - Quick Look Preview Data Source

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController*)controller
{
  return self.folder.files.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController*)controller
                     previewItemAtIndex:(NSInteger)index
{
  InfinitFileModel* file = self.folder.files[index];
  return [NSURL fileURLWithPath:file.path];
}

@end
