//
//  UIImage+Rounded.h
//  Infinit
//
//  Created by Christopher Crone on 16/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "UIImage+Rounded.h"

@implementation UIImage (Rounded)

- (UIImage*)circularMaskOfSize:(CGSize)size
{
  CGRect image_rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
  UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);
  UIBezierPath* circle_path = [UIBezierPath bezierPathWithOvalInRect:image_rect];
  [circle_path addClip];
  [self drawInRect:image_rect];

  UIImage* masked_image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return masked_image;
}

- (UIImage*)circularMask
{
  return [self circularMaskOfSize:self.size];
}

- (UIImage*)roundedMaskOfSize:(CGSize)size
                 cornerRadius:(CGFloat)radius
{
  CGRect image_rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
  UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);

  UIBezierPath* circle_path = [UIBezierPath bezierPathWithRoundedRect:image_rect
                                                         cornerRadius:radius];
  [circle_path addClip];
  [self drawInRect:image_rect];

  UIImage* masked_image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return masked_image;
}

@end
