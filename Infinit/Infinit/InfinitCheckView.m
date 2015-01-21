//
//  InfinitCheckView.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitCheckView.h"

#import "InfinitColor.h"

@interface InfinitCheckView ()

@property (nonatomic, strong) CAShapeLayer* check_layer;
@property (nonatomic, strong) CAShapeLayer* circle_layer;

@end

@implementation InfinitCheckView



- (void)awakeFromNib
{
  _circle_layer = [CAShapeLayer layer];
  self.circle_layer.fillColor = nil;
  self.circle_layer.strokeColor = [InfinitColor colorWithGray:211].CGColor;
  self.circle_layer.lineWidth = 1.0f;
  self.circle_layer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
  [self.layer addSublayer:self.circle_layer];

  _check_layer = [CAShapeLayer layer];
  self.check_layer.fillColor = nil;
  self.check_layer.strokeColor = [UIColor whiteColor].CGColor;
  self.check_layer.lineWidth = 3.5f;
  CGFloat w = self.frame.size.width;
  CGFloat h = self.frame.size.height;
  UIBezierPath* check = [UIBezierPath bezierPath];
  [check moveToPoint:CGPointMake(w * 1.0f / 4.0f, h * 1.0f / 2.0f)];
  [check addLineToPoint:CGPointMake(w * 3.0f / 8.0f, h * 2.0f / 3.0f)];
  [check addLineToPoint:CGPointMake(w * 3.0f / 4.0f, h * 3.0f / 8.0f)];
  self.check_layer.path = check.CGPath;
  self.check_layer.lineCap = kCALineCapRound;
  [self.layer addSublayer:self.check_layer];
}

- (void)setChecked:(BOOL)checked
          animated:(BOOL)animate
{
  if (checked == _checked)
    return;
  _checked = checked;
  if (checked)
  {
    self.check_layer.hidden = NO;
    self.circle_layer.strokeColor = [InfinitColor colorFromPalette:ColorShamRock].CGColor;
    self.circle_layer.fillColor = [InfinitColor colorFromPalette:ColorShamRock].CGColor;
  }
  else
  {
    self.check_layer.hidden = YES;
    self.circle_layer.strokeColor = [InfinitColor colorWithGray:211].CGColor;
    self.circle_layer.fillColor = nil;
  }
  if (animate)
  {
    if (checked)
    {
      CABasicAnimation* check_anim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
      check_anim.fromValue = @(0.0f);
      check_anim.toValue = @(1.0f);
      check_anim.duration = 0.2f;
      [self.check_layer addAnimation:check_anim forKey:@"strokeEnd"];
    }
  }
}

- (void)setChecked:(BOOL)checked
{
  [self setChecked:checked animated:NO];
}

@end
