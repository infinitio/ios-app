//
//  InfinitHomeAvatarView.m
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeAvatarView.h"

#import "InfinitColor.h"

#import "UIImage+Rounded.h"

@interface InfinitHomeAvatarView ()

@property (nonatomic, readonly) CAShapeLayer* circle_layer;
@property (nonatomic, readonly) CAShapeLayer* progress_layer;

@end

@implementation InfinitHomeAvatarView

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _enable_progress = NO;
  }
  return self;
}

- (void)setImage:(UIImage*)image
{
  self.image_view.image = [image circularMaskOfSize:self.image_view.bounds.size];
}

- (void)setProgress:(CGFloat)progress
{
  [self setProgress:progress withAnimationTime:0.0f];
}

- (void)setProgress:(CGFloat)progress
  withAnimationTime:(NSTimeInterval)duration
{
  if (_progress == progress)
    return;
  if (duration > 0.0f)
  {
    CGFloat last_progress = self.progress;
    self.progress_layer.strokeEnd = progress;
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = duration;
    animation.fromValue = @(last_progress);
    animation.toValue = @(progress);
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.progress_layer addAnimation:animation forKey:@"strokeEnd"];
  }
  else
  {
    self.progress_layer.strokeEnd = progress;
  }
  _progress = progress;
}

- (void)setEnable_progress:(BOOL)enable_progress
{
  if (enable_progress == _enable_progress)
    return;
  _enable_progress = enable_progress;
  if (_enable_progress)
  {
    _circle_layer = [self circleLayer];
    self.circle_layer.strokeColor = [InfinitColor colorWithGray:224].CGColor;
    [self.layer addSublayer:self.circle_layer];
    _progress_layer = [self circleLayer];
    self.progress_layer.strokeColor = [InfinitColor colorWithRed:43 green:190 blue:189].CGColor;
    self.progress_layer.strokeEnd = self.progress;
    [self.layer addSublayer:self.progress_layer];
  }
  else
  {
    [self.circle_layer removeFromSuperlayer];
    [self.progress_layer removeFromSuperlayer];
  }
}

#pragma mark - Helpers

- (CAShapeLayer*)circleLayer
{
  CAShapeLayer* res = [CAShapeLayer layer];
  CGFloat radius = self.bounds.size.width / 2.0f;
  CGPoint arc_center = CGPointMake(CGRectGetMidY(self.bounds), CGRectGetMidX(self.bounds));
  res.path = [UIBezierPath bezierPathWithArcCenter:arc_center
                                            radius:radius
                                        startAngle:-M_PI_2
                                          endAngle:(3.0f * M_PI_2)
                                         clockwise:YES].CGPath;
  res.fillColor = [UIColor clearColor].CGColor;
  res.lineWidth = 4.0f;
  return res;
}

@end
