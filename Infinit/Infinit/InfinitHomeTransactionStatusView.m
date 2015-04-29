//
//  InfinitHomeTransactionStatusView.m
//  Infinit
//
//  Created by Christopher Crone on 20/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeTransactionStatusView.h"

#import <Gap/InfinitColor.h>

@interface InfinitHomeTransactionStatusView ()

@property (nonatomic, strong) NSMutableArray* circles;

@end

static CGFloat _max_size = 10.0f;

@implementation InfinitHomeTransactionStatusView

#pragma mark - UIImageView

- (void)setImage:(UIImage*)image
{
  if (image != nil)
    self.run_transfer_animation = NO;
  [super setImage:image];
}

- (void)dealloc
{
  [self.layer removeAllAnimations];
  for (CAShapeLayer* layer in self.circles)
  {
    [layer removeAllAnimations];
    [layer removeFromSuperlayer];
  }
  _circles = nil;
}

#pragma mark - Transfer Animation

- (void)setRun_transfer_animation:(BOOL)animate
{
  if (self.run_transfer_animation == animate)
    return;
  _run_transfer_animation = animate;
  if (animate)
  {
    [super setImage:nil];
    _circles = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++)
    {
      CAShapeLayer* circle = [CAShapeLayer layer];
      circle.fillColor = [InfinitColor colorWithRed:81 green:81 blue:73].CGColor;
      CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"path"];
      CGPoint center = CGPointMake((self.bounds.size.width / 2.0f) + ((i - 1) * (_max_size + 2.0f)),
                                   self.bounds.size.height / 2.0f);
      UIBezierPath* start_circ =
      [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x, center.y, 0.0f, 0.0f)];
      anim.fromValue = (__bridge id)start_circ.CGPath;
      UIBezierPath* end_circ =
        [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - (_max_size / 2.0f),
                                                          center.y - (_max_size / 2.0f),
                                                          _max_size,
                                                          _max_size)];
      anim.toValue = (__bridge id)end_circ.CGPath;
      anim.timingFunction =
        [CAMediaTimingFunction functionWithControlPoints:0.8f :0.0f :0.6f :1.0f];
      anim.duration = 0.75f;
      anim.beginTime = CACurrentMediaTime() + (i * anim.duration / 4.0f);
      anim.repeatCount = HUGE_VALF;
      anim.autoreverses = YES;
      [circle addAnimation:anim forKey:anim.keyPath];
      [self.layer addSublayer:circle];
      [self.circles addObject:circle];
    }
  }
  else
  {
    [self.layer removeAllAnimations];
    for (CAShapeLayer* layer in self.circles)
    {
      [layer removeAllAnimations];
      [layer removeFromSuperlayer];
    }
    _circles = nil;
  }
}

@end
