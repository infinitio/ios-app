//
//  InfinitSendAbstractCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendAbstractCell.h"

#import "InfinitColor.h"

#import "UIImage+Rounded.h"

static NSDictionary* _norm_attrs = nil;
static NSDictionary* _selected_attrs = nil;

@interface InfinitSendAbstractCell ()

@property (nonatomic, strong) CAShapeLayer* check_layer;
@property (nonatomic, strong) CAShapeLayer* circle_layer;

@property (nonatomic) BOOL checked;

@end

@implementation InfinitSendAbstractCell

- (void)awakeFromNib
{
  if (_norm_attrs == nil)
  {
    _norm_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0f],
                    NSForegroundColorAttributeName: [InfinitColor colorWithGray:77]};
  }
  if (_selected_attrs == nil)
  {
    _selected_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0f],
                        NSForegroundColorAttributeName: [InfinitColor colorWithGray:26]};
  }
  _circle_layer = [CAShapeLayer layer];
  self.circle_layer.path = [UIBezierPath bezierPathWithOvalInRect:self.avatar_view.bounds].CGPath;
  [self.avatar_view.layer addSublayer:self.circle_layer];
  self.circle_layer.hidden = YES;

  _check_layer = [CAShapeLayer layer];
  self.check_layer.fillColor = nil;
  self.check_layer.strokeColor = [UIColor whiteColor].CGColor;
  self.check_layer.lineWidth = 2.75f;
  CGFloat w = self.avatar_view.frame.size.width;
  CGFloat h = self.avatar_view.frame.size.height;
  UIBezierPath* check = [UIBezierPath bezierPath];
  [check moveToPoint:CGPointMake(w * 1.0f / 3.25f, h * 1.0f / 2.0f)];
  [check addLineToPoint:CGPointMake(w * 3.2f / 8.0f, h * 2.0f / 3.0f)];
  [check addLineToPoint:CGPointMake(w * 2.75f / 4.0f, h * 3.0f / 8.0f)];
  self.check_layer.path = check.CGPath;
  self.check_layer.lineCap = kCALineCapRound;
  [self.avatar_view.layer addSublayer:self.check_layer];
  self.check_layer.hidden = YES;
}

- (void)prepareForReuse
{
  [self setChecked:NO];
}

- (void)setContact:(InfinitContact*)contact
{
  _contact = contact;
  self.avatar_view.image = [contact.avatar circularMaskOfSize:self.avatar_view.bounds.size];
  if (self.contact.infinit_user != nil && self.contact.infinit_user.is_self)
    self.name_label.text = NSLocalizedString(@"Me (other devices)", nil);
  else
    self.name_label.text = self.contact.fullname;
}

- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated
{
  NSMutableAttributedString* res = [self.name_label.attributedText mutableCopy];
  NSRange range = NSMakeRange(0, res.length);
  if (selected)
    [res setAttributes:_selected_attrs range:range];
  else
    [res setAttributes:_norm_attrs range:range];
  self.name_label.attributedText = res;
  [self setChecked:selected animated:YES];
  [super setSelected:selected animated:animated];
}

#pragma mark - Check

- (void)setChecked:(BOOL)checked
          animated:(BOOL)animate
{
  if (checked == _checked)
    return;
  _checked = checked;
  if (checked)
  {
    self.circle_layer.hidden = NO;
    self.check_layer.hidden = NO;
    self.circle_layer.fillColor = [InfinitColor colorWithGray:0 alpha:0.51f].CGColor;
  }
  else
  {
    self.circle_layer.hidden = YES;
    self.check_layer.hidden = YES;
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
