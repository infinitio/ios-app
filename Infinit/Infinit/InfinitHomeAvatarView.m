//
//  InfinitHomeAvatarView.m
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeAvatarView.h"

#import "InfinitColor.h"

#import "UIImage+circular.h"

@interface InfinitHomeAvatarView ()

@property (nonatomic, readonly) CAShapeLayer* circle_layer;
@property (nonatomic, readonly) CAShapeLayer* progress_layer;

@end

@implementation InfinitHomeAvatarView

static NSDictionary* _norm_attrs = nil;
static NSDictionary* _small_attrs = nil;

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _enable_progress = NO;
    if (_norm_attrs == nil || _small_attrs == nil)
    {
      NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      para.alignment = NSTextAlignmentCenter;
      _norm_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:52.0f],
                      NSForegroundColorAttributeName: [UIColor whiteColor],
                      NSParagraphStyleAttributeName: para};
      _small_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:16.0f],
                       NSForegroundColorAttributeName: [UIColor whiteColor],
                       NSParagraphStyleAttributeName: para};
    }
  }
  return self;
}

- (void)awakeFromNib
{
  self.progress_label.layer.masksToBounds = NO;
  self.progress_label.layer.shadowOpacity = 1.0f;
  self.progress_label.layer.shadowColor = [InfinitColor colorWithGray:0 alpha:0.63f].CGColor;
  self.progress_label.layer.shadowRadius = 5.0f;
  self.progress_label.layer.shadowOffset = CGSizeZero;
  self.progress_label.attributedText = [self progressString:0.0f];
}

- (void)setImage:(UIImage*)image
{
  self.image_view.image = image.circularMask;
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
    self.progress_label.attributedText = [self progressString:progress];
  }
  else
  {
    self.progress_label.attributedText = [self progressString:progress];
    self.progress_layer.strokeEnd = progress;
  }
  _progress = progress;
}

- (NSAttributedString*)progressString:(CGFloat)progress
{
  NSString* str = [NSString stringWithFormat:@"%.f%%", progress * 100.0f];
  NSMutableAttributedString* res = [[NSMutableAttributedString alloc] initWithString:str
                                                                          attributes:_norm_attrs];
  NSRange small_range = [res.string rangeOfString:@"%"];
  if (small_range.location != NSNotFound)
    [res setAttributes:_small_attrs range:small_range];
  return res;
}

- (void)setDim_avatar:(BOOL)dim_avatar
{
  self.image_view.alpha = dim_avatar ? 0.5f : 1.0f;
}

- (void)setEnable_progress:(BOOL)enable_progress
{
  if (enable_progress == _enable_progress)
    return;
  _enable_progress = enable_progress;
  if (!_enable_progress)
    self.progress_label.attributedText = [self progressString:0.0f];
  self.progress_label.hidden = !enable_progress;
  if (_enable_progress)
  {
    _circle_layer = [self circleLayer];
    self.circle_layer.strokeColor = [InfinitColor colorWithGray:255 alpha:0.5f].CGColor;
    [self.layer addSublayer:self.circle_layer];
    _progress_layer = [self circleLayer];
    self.progress_layer.strokeColor = [InfinitColor colorWithGray:255].CGColor;
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
