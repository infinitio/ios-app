//
//  UIImage+Rounded.h
//  Infinit
//
//  Created by Christopher Crone on 16/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Rounded)

- (UIImage*)circularMaskOfSize:(CGSize)size;
- (UIImage*)circularMask;
- (UIImage*)roundedMaskOfSize:(CGSize)size
                 cornerRadius:(CGFloat)radius;

@end
