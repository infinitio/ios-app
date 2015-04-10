//
//  InfinitProgressView.m
//  Infinit
//
//  Created by Christopher Crone on 08/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitProgressView.h"

#import "InfinitColor.h"

@interface InfinitProgressView ()

@property (nonatomic, readonly) NSMutableArray* circles;

@end

static float _max_size = 15.0f;

@implementation InfinitProgressView

- (void)setAnimate_progress:(BOOL)animate
{
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
      anim.fromValue = (__bridge id)[UIBezierPath bezierPathWithArcCenter:center
                                                                   radius:0.0f
                                                               startAngle:0.0f
                                                                 endAngle:(2.0f * M_PI)
                                                                clockwise:NO].CGPath;
      anim.toValue = (__bridge id)[UIBezierPath bezierPathWithArcCenter:center
                                                                 radius:(_max_size / 2.0f)
                                                             startAngle:0.0f
                                                               endAngle:(2.0f * M_PI)
                                                              clockwise:NO].CGPath;
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

- (void)setImage:(UIImage*)image
{
  self.animate_progress = NO;
  [super setImage:image];
}

@end
