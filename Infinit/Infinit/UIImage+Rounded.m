//
//  UIImage+Rounded.h
//  Infinit
//
//  Created by Christopher Crone on 16/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "UIImage+Rounded.h"

@implementation UIImage (infinit_Rounded)

- (UIImage*)infinit_circularMaskOfSize:(CGSize)size
{
  CGRect image_rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
  UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0.0, size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextAddPath(context, [UIBezierPath bezierPathWithOvalInRect:image_rect].CGPath);
  CGContextClip(context);
  CGContextSetBlendMode(context, kCGBlendModeCopy);
  CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), self.CGImage);

  UIImage* masked_image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return masked_image;
}

- (UIImage*)infinit_circularMask
{
  return [self infinit_circularMaskOfSize:self.size];
}

- (UIImage*)infinit_roundedMaskOfSize:(CGSize)size
                         cornerRadius:(CGFloat)radius
{
  CGRect image_rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
  UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0.0, size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextAddPath(context,
                   [UIBezierPath bezierPathWithRoundedRect:image_rect cornerRadius:radius].CGPath);
  CGContextClip(context);
  CGContextSetBlendMode(context, kCGBlendModeCopy);
  CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), self.CGImage);

  UIImage* masked_image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return masked_image;
}

@end
