//
//  UIImage+Rounded.h
//  Infinit
//
//  Created by Christopher Crone on 16/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "UIImage+Rounded.h"

@implementation UIImage (Rounded)

- (UIImage*)circularMask
{
  CGRect image_rect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
  UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);

  UIBezierPath* circle_path = [UIBezierPath bezierPathWithOvalInRect:image_rect];
  [circle_path addClip];
  [self drawInRect:image_rect];

  UIImage* masked_image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return masked_image;
}

- (UIImage*)roundedMaskWithCornerRadius:(CGFloat)radius
{
  CGRect image_rect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
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
