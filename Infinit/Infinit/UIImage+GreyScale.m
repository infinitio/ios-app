//
//  UIImage+GreyScale.m
//  Infinit
//
//  Created by Chris Crone on 05/10/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "UIImage+GreyScale.h"

@implementation UIImage (infinit_GreyScale)

- (UIImage*)infinit_grey_scale_image
{
  CGRect image_rect = CGRectMake(0, 0, self.scaled_size.width, self.scaled_size.height);
  CGColorSpaceRef color_space_ref = CGColorSpaceCreateDeviceGray();
  CGContextRef context_ref = CGBitmapContextCreate(
    nil, self.scaled_size.width, self.scaled_size.height, 8, 0, color_space_ref, kCGImageAlphaNone);
  CGContextDrawImage(context_ref, image_rect, self.CGImage);
  CGImageRef base_image_ref = CGBitmapContextCreateImage(context_ref);
  CGColorSpaceRelease(color_space_ref);
  CGContextRelease(context_ref);
  context_ref = CGBitmapContextCreate(
    nil, self.scaled_size.width, self.scaled_size.height, 8, 0, nil, kCGImageAlphaOnly);
  CGContextDrawImage(context_ref, image_rect, self.CGImage);
  CGImageRef mask = CGBitmapContextCreateImage(context_ref);
  CGContextRelease(context_ref);
  CGImageRef image_ref = CGImageCreateWithMask(base_image_ref, mask);
  UIImage* res =
    [UIImage imageWithCGImage:image_ref scale:self.scale orientation:self.imageOrientation];
  CGImageRelease(base_image_ref);
  CGImageRelease(image_ref);
  CGImageRelease(mask);
  return res;
}

- (CGSize)scaled_size
{
  return CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
}

@end
