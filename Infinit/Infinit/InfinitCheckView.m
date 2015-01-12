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

@end

@implementation InfinitCheckView



- (void)awakeFromNib
{
  self.layer.cornerRadius = self.frame.size.width / 2.0f;
  self.clipsToBounds = YES;
  self.layer.borderColor = [InfinitColor colorFromPalette:ColorShamRock].CGColor;
  self.layer.borderWidth = 1.0f;

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
  [self.layer addSublayer:self.check_layer];
}

- (void)setChecked:(BOOL)checked
          animated:(BOOL)animate
{
  if (checked == _checked)
    return;
  _checked = checked;
  UIColor* start_color = nil;
  UIColor* end_color = nil;
  if (checked)
  {
    start_color = [UIColor whiteColor];
    end_color = [InfinitColor colorFromPalette:ColorShamRock];
    self.check_layer.hidden = NO;
  }
  else
  {
    start_color = [InfinitColor colorFromPalette:ColorShamRock];
    end_color = [UIColor whiteColor];
    self.check_layer.hidden = YES;
  }
  self.layer.backgroundColor = end_color.CGColor;
  if (animate)
  {
    CABasicAnimation* color_anim = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    color_anim.fromValue = (__bridge id)(start_color.CGColor);
    color_anim.toValue = (__bridge id)(end_color.CGColor);
    color_anim.duration = 0.3f;
    [self.layer addAnimation:color_anim forKey:@"backgroundColor"];
    if (checked)
    {
      CABasicAnimation* check_anim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
      check_anim.fromValue = @(0.0f);
      check_anim.toValue = @(1.0f);
      check_anim.duration = 0.3f;
      [self.check_layer addAnimation:check_anim forKey:@"strokeEnd"];
    }
  }
}

- (void)setChecked:(BOOL)checked
{
  [self setChecked:checked animated:NO];
}

@end
