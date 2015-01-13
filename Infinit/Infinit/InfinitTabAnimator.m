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

  if (self.animation == AnimateRightLeft || self.animation == AnimateDownUp)
  {
    CGRect container = [transitionContext containerView].bounds;
    CGRect old_end;
    if (self.animation == AnimateRightLeft)
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
    else if (self.animation == AnimateDownUp)
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
  else if (self.animation == AnimateCircleCover)
  {
    CGFloat radius = hypotf(new_vc.view.frame.size.width, new_vc.view.frame.size.height);
    CGRect start_rect;
    CGRect final_rect;
    UIView* animate_view;
    if (self.reverse)
    {
      animate_view = old_vc.view;
      start_rect = CGRectMake(self.animation_center.x - radius, self.animation_center.y - radius,
                              2.0f * radius, 2.0f * radius);
      final_rect = CGRectMake(self.animation_center.x, self.animation_center.y, 0.0f, 0.0f);
    }
    else
    {
      animate_view = new_vc.view;
      start_rect = CGRectMake(self.animation_center.x, self.animation_center.y, 0.0f, 0.0f);
      final_rect = CGRectMake(self.animation_center.x - radius, self.animation_center.y - radius,
                              2.0f * radius, 2.0f * radius);
    }
    [[transitionContext containerView] bringSubviewToFront:animate_view];
    animate_view.layer.mask = [self animatedMaskLayerFrom:start_rect
                                                       to:final_rect
                                             withDuration:[self transitionDuration:transitionContext]
                                       andCompletionBlock:^
    {
      [transitionContext completeTransition:YES];
      [old_vc.view removeFromSuperview];
    }];
  }
}

#pragma mark Helpers

- (CALayer*)animatedMaskLayerFrom:(CGRect)start_rect
                               to:(CGRect)final_rect
                     withDuration:(CGFloat)duration
               andCompletionBlock:(void (^)(void))block
{
  [CATransaction begin];
  CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"path"];
  anim.duration = 0.5f;
  anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  anim.fromValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:start_rect].CGPath);
  anim.toValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:final_rect].CGPath);
  CAShapeLayer* res = [CAShapeLayer layer];
  res.path = [UIBezierPath bezierPathWithOvalInRect:final_rect].CGPath;
  res.backgroundColor = [UIColor blackColor].CGColor;
  [CATransaction setCompletionBlock:block];
  [res addAnimation:anim forKey:anim.keyPath];
  [CATransaction commit];
  return res;
}

@end
