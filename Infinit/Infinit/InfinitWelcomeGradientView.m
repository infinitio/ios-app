//
//  InfinitWelcomeGradientView.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeGradientView.h"

#import "InfinitColor.h"

@interface InfinitWelcomeGradientView ()

@property (nonatomic, strong) CAGradientLayer* gradient_layer;

@end

@implementation InfinitWelcomeGradientView

- (void)layoutSublayersOfLayer:(CALayer*)layer
{
  [super layoutSublayersOfLayer:layer];
  if (layer == self.layer)
  {
    [self.gradient_layer removeFromSuperlayer];
    _gradient_layer = [self makeLayer];
    [self.layer insertSublayer:self.gradient_layer atIndex:0];
  }
}

#pragma mark - Helpers

- (CAGradientLayer*)makeLayer
{
  CAGradientLayer* res = [CAGradientLayer layer];
  res.frame = self.bounds;
  res.startPoint = CGPointMake(0.0f, 0.0f);
  res.endPoint = CGPointMake(0.0f, 0.7f);
  res.colors = @[(id)[InfinitColor colorWithRed:226 green:228 blue:227].CGColor,
                 (id)[InfinitColor colorWithRed:227 green:231 blue:233].CGColor,
                 (id)[InfinitColor colorWithRed:230 green:235 blue:238].CGColor,
                 (id)[InfinitColor colorWithRed:234 green:240 blue:243].CGColor,
                 (id)[InfinitColor colorWithRed:239 green:244 blue:248].CGColor,
                 (id)[InfinitColor colorWithRed:240 green:250 blue:251].CGColor,
                 (id)[InfinitColor colorWithRed:244 green:252 blue:252].CGColor,
                 (id)[InfinitColor colorWithRed:246 green:252 blue:252].CGColor,
                 (id)[InfinitColor colorWithRed:255 green:255 blue:255].CGColor];
  return res;
}

@end
