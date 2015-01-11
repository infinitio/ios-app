//
//  InfinitTabAnimator.m
//  Infinit
//
//  Created by Christopher Crone on 11/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitTabAnimator.h"

@implementation InfinitTabAnimator

- (id)init
{
  if (self = [super init])
  {
    self.duration = 0.3f;
  }
  return self;
}

#pragma mark Protocol

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
  return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  UIViewController* old_vc =
    [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController* new_vc =
    [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

  [[transitionContext containerView] addSubview:new_vc.view];
  new_vc.view.frame = [transitionContext finalFrameForViewController:new_vc];
  [new_vc.view layoutIfNeeded];

  CGRect container = [transitionContext containerView].bounds;
  CGRect old_end;
  if (self.up_animation)
  {
    if (self.reverse)
    {
      [[transitionContext containerView] bringSubviewToFront:old_vc.view];
      old_end = CGRectMake(new_vc.view.frame.origin.x,
                           new_vc.view.frame.size.height,
                           new_vc.view.frame.size.width,
                           new_vc.view.frame.size.height);
    }
    else
    {
      new_vc.view.frame = CGRectMake(container.origin.x,
                                     new_vc.view.frame.size.height,
                                     new_vc.view.frame.size.width,
                                     new_vc.view.frame.size.height);
      old_end = old_vc.view.frame;
    }
  }
  else
  {
    old_end = CGRectMake(self.reverse ? container.size.width : - container.size.width,
                         container.origin.y,
                         container.size.width,
                         container.size.height);
    CGRect new_start = CGRectMake(self.reverse ? - container.size.width : container.size.width,
                                  new_vc.view.frame.origin.y,
                                  new_vc.view.frame.size.width,
                                  new_vc.view.frame.size.height);
    new_vc.view.frame = new_start;
  }

  [UIView animateWithDuration:[self transitionDuration:transitionContext]
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     old_vc.view.frame = old_end;
     new_vc.view.frame = [transitionContext finalFrameForViewController:new_vc];
   } completion:^(BOOL finished)
   {
     [transitionContext completeTransition:YES];
     [old_vc.view removeFromSuperview];
   }];
}

@end
