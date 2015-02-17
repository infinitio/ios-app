//
//  InfinitTabAnimator.m
//  Infinit
//
//  Created by Christopher Crone on 11/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitTabAnimator.h"

#import "InfinitColor.h"

@implementation InfinitTabAnimator

- (id)init
{
  if (self = [super init])
  {
    self.circular_duration = 0.4f;
    self.linear_duration = self.circular_duration / 2.0f;
  }
  return self;
}

#pragma mark - Protocol

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
  switch (self.animation)
  {
    case AnimateRightLeft:
    case AnimateDownUp:
      return self.linear_duration;
    case AnimateCircleCover:
      return self.circular_duration;

    default:
      return self.linear_duration;
  }
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
    CGSize button_size = CGSizeMake(68.0f, 73.0f);
    CGRect start_rect;
    CGRect final_rect;
    UIColor* from_color;
    UIColor* to_color;
    NSTimeInterval color_duration = [self transitionDuration:transitionContext] / 2.0f;
    NSTimeInterval color_offset;
    UIView* animate_view = [[UIView alloc] initWithFrame:[transitionContext containerView].frame];
    animate_view.backgroundColor = [UIColor clearColor];
    [[UIApplication sharedApplication].keyWindow addSubview:animate_view];

    if (self.reverse)
    {
      from_color = [InfinitColor colorWithGray:46];
      to_color = [InfinitColor colorFromPalette:ColorBurntSienna];
      color_offset = 1.0f / 2.0f * [self transitionDuration:transitionContext];
      start_rect = CGRectMake(self.animation_center.x - radius, self.animation_center.y - radius,
                              2.0f * radius, 2.0f * radius);
      CGPoint animation_origin = CGPointMake(self.animation_center.x - (button_size.width / 2.0f),
                                             self.animation_center.y - (button_size.height / 2.0f));
      final_rect = CGRectMake(animation_origin.x, animation_origin.y,
                              button_size.width, button_size.height);
      [[transitionContext containerView] bringSubviewToFront:old_vc.view];
      animate_view.alpha = 0.0f;
      animate_view.backgroundColor = from_color;
      [[UIApplication sharedApplication].keyWindow bringSubviewToFront:animate_view];
      [UIView animateWithDuration:self.linear_duration
                            delay:0.0f
                          options:UIViewAnimationOptionCurveLinear
                       animations:^
      {
        animate_view.alpha = 1.0f;
      } completion:^(BOOL finished)
      {
        animate_view.backgroundColor = [UIColor clearColor];
        if (!finished)
          animate_view.alpha = 1.0f;
        [[transitionContext containerView] sendSubviewToBack:old_vc.view];
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationNone];
        CAShapeLayer* color_layer = [self animatedMaskLayerFrom:start_rect
                                                             to:final_rect
                                               withPathDuration:[self transitionDuration:transitionContext]
                                                      fromColor:from_color
                                                        toColor:to_color
                                              withColorDuration:color_duration
                                                 andBeginOffset:color_offset
                                             andCompletionBlock:^
         {
           [animate_view removeFromSuperview];
           [transitionContext completeTransition:YES];
           [old_vc.view removeFromSuperview];
         }];
        [animate_view.layer addSublayer:color_layer];
      }];
    }
    else
    {
      from_color = [InfinitColor colorFromPalette:ColorBurntSienna];
      to_color = [InfinitColor colorWithGray:46];
      color_offset = 0.0f;
      CGPoint animation_origin = CGPointMake(self.animation_center.x - (button_size.width / 2.0f),
                                             self.animation_center.y - (button_size.height / 2.0f));
      start_rect = CGRectMake(animation_origin.x, animation_origin.y,
                              button_size.width, button_size.height);
      final_rect = CGRectMake(self.animation_center.x - radius, self.animation_center.y - radius,
                              2.0f * radius, 2.0f * radius);
      [[transitionContext containerView] bringSubviewToFront:old_vc.view];
      animate_view.alpha = 1.0f;
      [[UIApplication sharedApplication].keyWindow bringSubviewToFront:animate_view];
      [[UIApplication sharedApplication] setStatusBarHidden:YES
                                              withAnimation:UIStatusBarAnimationFade];
      CAShapeLayer* color_layer = [self animatedMaskLayerFrom:start_rect
                                                           to:final_rect
                                             withPathDuration:[self transitionDuration:transitionContext]
                                                    fromColor:from_color
                                                      toColor:to_color
                                            withColorDuration:color_duration
                                               andBeginOffset:color_offset
                                           andCompletionBlock:^
       {
         [UIView animateWithDuration:self.linear_duration
                               delay:0.0f
                             options:UIViewAnimationOptionCurveLinear
                          animations:^
          {
            [[transitionContext containerView] sendSubviewToBack:old_vc.view];
            animate_view.alpha = 0.0f;
          } completion:^(BOOL finished)
          {
            [animate_view removeFromSuperview];
            [transitionContext completeTransition:YES];
            [old_vc.view removeFromSuperview];
          }];
       }];
      [animate_view.layer addSublayer:color_layer];
    }
  }
}

#pragma mark - Helpers

- (CAShapeLayer*)animatedMaskLayerFrom:(CGRect)start_rect
                                    to:(CGRect)final_rect
                      withPathDuration:(NSTimeInterval)path_duration
                             fromColor:(UIColor*)from_color
                               toColor:(UIColor*)to_color
                     withColorDuration:(NSTimeInterval)color_duration
                        andBeginOffset:(NSTimeInterval)color_begin_offset
                    andCompletionBlock:(void (^)(void))block
{
  CAShapeLayer* res = [CAShapeLayer layer];
  res.path = [UIBezierPath bezierPathWithOvalInRect:start_rect].CGPath;
  res.fillColor = from_color.CGColor;

  [CATransaction begin];
  CABasicAnimation* path_anim = [CABasicAnimation animationWithKeyPath:@"path"];
  NSString* timing_func = kCAMediaTimingFunctionEaseInEaseOut;
  path_anim.duration = path_duration;
  path_anim.timingFunction = [CAMediaTimingFunction functionWithName:timing_func];
  path_anim.fromValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:start_rect].CGPath);
  path_anim.toValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:final_rect].CGPath);
  path_anim.fillMode = kCAFillModeForwards;
  path_anim.removedOnCompletion = NO;

  CABasicAnimation* color_anim = [CABasicAnimation animationWithKeyPath:@"fillColor"];
  color_anim.duration = color_duration;
  color_anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  color_anim.fromValue = (__bridge id)from_color.CGColor;
  color_anim.toValue = (__bridge id)to_color.CGColor;
  color_anim.fillMode = kCAFillModeForwards;
  color_anim.removedOnCompletion = NO;

  if (self.reverse)
  {
    path_anim.beginTime = CACurrentMediaTime();
    color_anim.beginTime = path_anim.beginTime + color_begin_offset;
  }
  else
  {
    path_anim.beginTime = CACurrentMediaTime();
    color_anim.beginTime = path_anim.beginTime;
  }

  [CATransaction setCompletionBlock:block];

  [res addAnimation:path_anim forKey:path_anim.keyPath];
  [res addAnimation:color_anim forKey:color_anim.keyPath];
  [CATransaction commit];
  return res;
}

@end
