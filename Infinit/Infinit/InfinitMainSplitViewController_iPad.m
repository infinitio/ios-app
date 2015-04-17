//
//  InfinitMainSplitViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMainSplitViewController_iPad.h"

#import "InfinitHostDevice.h"
#import "InfinitHomeViewController.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitSplitViewOverlayViewController.h"

@interface InfinitMainSplitViewController_iPad ()

@property (nonatomic, strong) InfinitSplitViewOverlayViewController* overlay_controller;
@property (nonatomic, strong) InfinitSendRecipientsController* recipient_controller;
@property (nonatomic, strong) UITabBarController* tab_controller;

@end

@implementation InfinitMainSplitViewController_iPad

#pragma mark - UISplitViewController

- (BOOL)splitViewController:(UISplitViewController*)svc
   shouldHideViewController:(UIViewController*)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
  return NO;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if ([InfinitHostDevice iOSVersion] >= 8.0)
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

#pragma mark - Public

- (void)showSendViewForFiles:(NSArray*)files
{
  if (files.count == 0)
    return;
  if (self.overlay_controller == nil)
  {
    UINib* overlay_nib =
      [UINib nibWithNibName:NSStringFromClass(InfinitSplitViewOverlayViewController.class)
                     bundle:nil];

    _overlay_controller = [overlay_nib instantiateWithOwner:self options:nil].firstObject;
  }
  if (self.recipient_controller == nil)
  {
    _recipient_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"send_recipients_controller"];
  }
  else
  {
    [self.recipient_controller resetView];
  }
  self.recipient_controller.files = files;
  [self.overlay_controller showController:self.recipient_controller];
}

#pragma mark - Helpers

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

@end
