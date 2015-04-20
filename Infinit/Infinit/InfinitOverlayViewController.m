//
//  InfinitOverlayViewController.m
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitOverlayViewController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

@interface InfinitOverlayViewController ()

@property (nonatomic, weak) IBOutlet UIButton* close_button;
@property (nonatomic, weak) IBOutlet UIView* content_view;
@property (nonatomic, weak) UIViewController* current_controller;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* w_constraint;

@end

static CGFloat _corner_radius = 0.0f;
static CGFloat _content_width = 0.0f;

@implementation InfinitOverlayViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      _corner_radius = 7.0f;
      _content_width = 468.0f;
    }
    else
    {
      _corner_radius = 3.0f;
      _content_width = 270.0f;
    }
  }
  return self;
}

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
  _visible = YES;
  self.w_constraint.constant = _content_width;
  self.close_button.hidden = NO;
  if (self.current_controller)
  {
    UIViewController* old_controller = self.current_controller;
    [controller willMoveToParentViewController:self];
    controller.view.frame = self.content_view.bounds;
    controller.view.layer.masksToBounds = YES;
    controller.view.layer.cornerRadius = _corner_radius;
    [self.content_view addSubview:controller.view];
    controller.view.transform =
      CGAffineTransformMakeTranslation(self.content_view.bounds.size.width, 0.0f);
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:controller];
    CAShapeLayer* mask = [CAShapeLayer layer];
    mask.path = [UIBezierPath bezierPathWithRoundedRect:self.content_view.bounds
                                           cornerRadius:_corner_radius].CGPath;
    self.content_view.layer.mask = mask;
    [UIView animateWithDuration:0.3f animations:^
    {
      controller.view.transform = CGAffineTransformIdentity;
      old_controller.view.transform =
        CGAffineTransformMakeTranslation(-self.content_view.bounds.size.width, 0.0f);
    } completion:^(BOOL finished)
    {
      controller.view.transform = CGAffineTransformIdentity;
      [old_controller removeFromParentViewController];
      [old_controller.view removeFromSuperview];
      _current_controller = controller;
      old_controller.view.transform = CGAffineTransformIdentity;
      [mask removeFromSuperlayer];
    }];
  }
  else
  {
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
    controller.view.layer.cornerRadius = _corner_radius;
    [self.content_view addSubview:controller.view];
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:controller];
    [self.view bringSubviewToFront:self.close_button];
    [self.view bringSubviewToFront:self.content_view];
    self.close_button.alpha = 0.0f;
    self.content_view.transform =
      CGAffineTransformMakeTranslation(0.0f, -self.view.bounds.size.height / 7.5f);
    [UIView animateWithDuration:0.3f
                     animations:^
    {
      self.view.alpha = 1.0f;
    } completion:^(BOOL finished)
    {
      self.view.alpha = 1.0f;
    }];
    [UIView animateWithDuration:0.3f
                          delay:0.2f
                        options:0
                     animations:^
     {
       self.close_button.alpha = 1.0f;
       self.content_view.transform = CGAffineTransformIdentity;
     } completion:^(BOOL finished)
     {
       self.content_view.transform = CGAffineTransformIdentity;
     }];
  }
}

- (void)hideController
{
  [self hideControllerWithCompletionHandler:NULL];
}

- (void)hideControllerWithCompletionHandler:(void (^)())completion_handler
{
  if (self.current_controller == nil)
    return;
  [self.current_controller willMoveToParentViewController:nil];
  self.content_view.transform = CGAffineTransformIdentity;
  self.close_button.hidden = YES;
  [UIView animateWithDuration:0.3f
                   animations:^
  {
    self.content_view.transform =
      CGAffineTransformMakeTranslation(0.0f, self.view.bounds.size.height / 7.5f);
    self.close_button.alpha = 0.0f;
  } completion:^(BOOL finished)
  {
    self.content_view.transform =
      CGAffineTransformMakeTranslation(0.0f, self.view.bounds.size.height / 7.5f);;
  }];
  [UIView animateWithDuration:0.3f
                        delay:0.2f 
                      options:0
                   animations:^
   {
     self.view.alpha = 0.0f;
   } completion:^(BOOL finished)
   {
     self.view.alpha = 0.0f;
     [self.current_controller.view removeFromSuperview];
     [self.current_controller removeFromParentViewController];
     [self.view removeFromSuperview];
     self.content_view.transform = CGAffineTransformIdentity;
     self.close_button.alpha = 1.0f;
     _visible = NO;
     if (completion_handler != NULL)
       completion_handler();
     _current_controller = nil;
   }];
}

#pragma mark - Button Handling

- (IBAction)closeTapped:(id)sender
{
  [self hideControllerWithCompletionHandler:^
  {
    [self.delegate overlayViewController:self userDidCancelController:self.current_controller];
  }];
}

@end
