//
//  InfinitColor.h
//  Infinit
//
//  Created by Christopher Crone on 08/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, InfinitPaletteColor)
{
  ColorBurntSienna, // 242, 94, 90
  ColorShamRock,    // 43, 190, 189
  ColorChicago,     // 100, 100, 90
};

@interface InfinitColor : NSObject

+ (UIColor*)colorWithGray:(NSUInteger)gray;
+ (UIColor*)colorWithGray:(NSUInteger)gray alpha:(CGFloat)alpha;

+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue;
+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue
                   alpha:(CGFloat)alpha;

+ (UIColor*)colorFromPalette:(InfinitPaletteColor)color;
+ (UIColor*)colorFromPalette:(InfinitPaletteColor)color
                       alpha:(CGFloat)alpha;

@end
