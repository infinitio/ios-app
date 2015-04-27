//
//  UIImage+Rounded.h
//  Infinit
//
//  Created by Christopher Crone on 16/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (infinit_Rounded)

- (UIImage*)infinit_circularMaskOfSize:(CGSize)size;
- (UIImage*)infinit_circularMask;
- (UIImage*)infinit_roundedMaskOfSize:(CGSize)size
                         cornerRadius:(CGFloat)radius;

@end
