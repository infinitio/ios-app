//
//  InfinitColor.m
//  Infinit
//
//  Created by Christopher Crone on 08/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitColor.h"

@implementation InfinitColor

+ (UIColor*)colorWithGray:(NSUInteger)gray
{
  return [InfinitColor colorWithGray:gray alpha:1.0];
}

+ (UIColor*)colorWithGray:(NSUInteger)gray alpha:(CGFloat)alpha
{
  return [InfinitColor colorWithRed:gray green:gray blue:gray alpha:alpha];
}

+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue
{
  return [InfinitColor colorWithRed:red green:green blue:blue alpha:1.0];
}

+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue
                 alpha:(CGFloat)alpha
{
  return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}

+ (UIColor*)colorFromPalette:(InfinitPaletteColor)color
{
  return [InfinitColor colorFromPalette:color alpha:1.0];
}

+ (UIColor*)colorFromPalette:(InfinitPaletteColor)color
                       alpha:(CGFloat)alpha
{
  switch (color)
  {
    case ColorBurntSienna:
      return [InfinitColor colorWithRed:242 green:94 blue:90 alpha:alpha];
    case ColorShamRock:
      return [InfinitColor colorWithRed:43 green:190 blue:189 alpha:alpha];
    case ColorChicago:
      return [InfinitColor colorWithRed:100 green:100 blue:90 alpha:alpha];

    default:
      return [InfinitColor colorWithRed:0 green:0 blue:0 alpha:alpha];
  }
}

@end
