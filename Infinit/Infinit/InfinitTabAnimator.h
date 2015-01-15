//
//  InfinitTabAnimator.h
//  Infinit
//
//  Created by Christopher Crone on 11/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, InfinitAnimations) {
  AnimateRightLeft,
  AnimateDownUp,
  AnimateCircleCover,
};

@interface InfinitTabAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, readwrite) InfinitAnimations animation;
@property (nonatomic, readwrite) CGPoint animation_center;
@property (nonatomic, readwrite) NSTimeInterval circular_duration;
@property (nonatomic, readwrite) NSTimeInterval linear_duration;
@property (nonatomic, readwrite) BOOL reverse;

@end
