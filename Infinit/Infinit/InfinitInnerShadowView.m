//
//  InfinitInnerShadowView.m
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInnerShadowView.h"

#import "InfinitColor.h"

@implementation InfinitInnerShadowView

- (void)drawRect:(CGRect)rect
{
  UIBezierPath* bg_path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:3.0f];
  [[UIColor whiteColor] set];
  [bg_path fill];
  UIColor* shadow_color = [InfinitColor colorWithGray:0 alpha:0.5f];
  [self drawInnerShadowInContext:UIGraphicsGetCurrentContext()
                        withPath:bg_path.CGPath
                     shadowColor:shadow_color.CGColor
                          offset:CGSizeMake(0.0f, 1.0f)
                      blurRadius:3.0f];
}

- (void)drawInnerShadowInContext:(CGContextRef)context
                        withPath:(CGPathRef)path
                     shadowColor:(CGColorRef)shadowColor
                          offset:(CGSize)offset
                      blurRadius:(CGFloat)blurRadius
{
  CGContextSaveGState(context);

  CGContextAddPath(context, path);
  CGContextClip(context);

  CGColorRef opaqueShadowColor = CGColorCreateCopyWithAlpha(shadowColor, 1.0);

  CGContextSetAlpha(context, CGColorGetAlpha(shadowColor));
  CGContextBeginTransparencyLayer(context, NULL);
  CGContextSetShadowWithColor(context, offset, blurRadius, opaqueShadowColor);
  CGContextSetBlendMode(context, kCGBlendModeSourceOut);
  CGContextSetFillColorWithColor(context, opaqueShadowColor);
  CGContextAddPath(context, path);
  CGContextFillPath(context);
  CGContextEndTransparencyLayer(context);

  CGContextRestoreGState(context);

  CGColorRelease(opaqueShadowColor);
}

@end
