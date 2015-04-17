//
//  InfinitSplitViewOverlayViewController.m
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSplitViewOverlayViewController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

@interface InfinitSplitViewOverlayViewController ()

@property (nonatomic, weak) IBOutlet UIButton* close_button;
@property (nonatomic, weak) IBOutlet UIView* content_view;
@property (nonatomic, weak) UIViewController* current_controller;

@end

@implementation InfinitSplitViewOverlayViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  if ([InfinitHostDevice iOSVersion] >= 8.0)
  {
    UIBlurEffect* effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView* effect_view = [[UIVisualEffectView alloc] initWithEffect:effect];
    effect_view.frame = self.view.bounds;
    [self.view insertSubview:effect_view belowSubview:self.content_view];
    NSDictionary* effect_views = @{@"view": effect_view};
    NSMutableArray* blur_constraints =
      [NSMutableArray arrayWithArray:
       [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                               options:0
                                               metrics:nil
                                                 views:effect_views]];
    [blur_constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                             options:0
                                             metrics:nil
                                               views:effect_views]];
    [self.view addConstraints:blur_constraints];
    effect_view.translatesAutoresizingMaskIntoConstraints = NO;
  }
  else
  {
    self.view.backgroundColor = [InfinitColor colorWithGray:0 alpha:0.5f];
  }
  self.content_view.backgroundColor = [UIColor clearColor];
  self.content_view.layer.shadowColor = [InfinitColor colorWithGray:0].CGColor;
  self.content_view.layer.shadowOpacity = 0.75f;
  self.content_view.layer.shadowRadius = 10.0f;
  self.content_view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
}

- (void)showController:(UIViewController*)controller
{
  if (self.current_controller == controller)
    return;
  _current_controller = controller;
  UIView* main_view = [UIApplication sharedApplication].keyWindow;
  self.view.alpha = 0.0f;
  [main_view addSubview:self.view];
  NSDictionary* views = @{@"view": self.view};
  NSMutableArray* constraints =
    [NSMutableArray arrayWithArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views]];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                           options:0 
                                                                           metrics:nil
                                                                             views:views]];
  [main_view addConstraints:constraints];
  self.view.frame = main_view.bounds;
  [controller willMoveToParentViewController:self];
  controller.view.frame = self.content_view.bounds;
  controller.view.layer.masksToBounds = YES;
  controller.view.layer.cornerRadius = 7.0f;
  [self.content_view addSubview:controller.view];
  [self addChildViewController:controller];
  [controller didMoveToParentViewController:controller];
  [UIView animateWithDuration:0.3f
                   animations:^
  {
    self.view.alpha = 1.0f;
  } completion:^(BOOL finished)
  {
    self.view.alpha = 1.0f;
    self.content_view.layer.shadowPath =
      [UIBezierPath bezierPathWithRoundedRect:self.content_view.bounds cornerRadius:7.0f].CGPath;
  }];
}

- (void)hideController
{
  if (self.current_controller == nil)
    return;
  [self.current_controller willMoveToParentViewController:nil];
  [UIView animateWithDuration:0.3f animations:^
  {
    self.view.alpha = 0.0f;
  } completion:^(BOOL finished)
  {
    self.view.alpha = 0.0f;
    [self.current_controller.view removeFromSuperview];
    [self.current_controller removeFromParentViewController];
    [self.view removeFromSuperview];
    _current_controller = nil;
  }];
}

#pragma mark - Button Handling

- (IBAction)closeTapped:(id)sender
{
  [self hideController];
}

@end
