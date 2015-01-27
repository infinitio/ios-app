//
//  InfinitFilePreviewController.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilePreviewController.h"

#import "InfinitColor.h"
#import "InfinitFilePreview.h"

@import QuickLook;

@interface InfinitFilePreviewController () <QLPreviewControllerDataSource,
                                            QLPreviewControllerDelegate>

@end

@implementation InfinitFilePreviewController

- (UIViewController*)presentingViewController
{
  return nil;
}

#pragma mark - Init

+ (instancetype)controllerWithFile:(InfinitFileModel*)file
{
  InfinitFilePreviewController* res = [[InfinitFilePreviewController alloc] init];
  res.file = file;
  return res;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = self.file.name;
  UINavigationBar* nav_bar = self.navigationController.navigationBar;
  nav_bar.tintColor = [InfinitColor colorFromPalette:ColorBurntSienna];
  UIBarButtonItem* back_button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-back-white"] style:UIBarButtonItemStylePlain target:self action:@selector(backTapped:)];
  
  self.navigationItem.leftBarButtonItem = back_button;
//  nav_bar.backIndicatorImage = [UIImage imageNamed:@"icon-back-white"];
//  nav_bar.backIndicatorTransitionMaskImage = [UIImage imageNamed:@"icon-back-white"];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.navigationController.toolbar.tintColor = [InfinitColor colorFromPalette:ColorBurntSienna];
  self.delegate = self;
  self.dataSource = self;
}

- (void)backTapped:(id)sender
{
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setFile:(InfinitFileModel*)file
{
  _file = file;
  [self reloadData];
}

#pragma mark - Navigation Controller Delegate

- (BOOL)hidesBottomBarWhenPushed
{
  return YES;
}

#pragma mark - Quick Look Preview Data Source

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController*)controller
{
  return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController*)controller
                     previewItemAtIndex:(NSInteger)index
{
  return [NSURL fileURLWithPath:self.file.path];
}

@end
