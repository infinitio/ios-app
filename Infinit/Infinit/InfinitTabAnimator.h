//
//  InfinitTabAnimator.h
//  Infinit
//
//  Created by Christopher Crone on 11/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface InfinitTabAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readwrite) BOOL reverse;
@property (nonatomic, readwrite) BOOL up_animation;

@end
