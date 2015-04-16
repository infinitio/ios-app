//
//  InfinitHomeOnboardingItem.h
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, InfinitHomeOnboardingCellType)
{
  InfinitHomeOnboardingCellSwipe = 0,
  InfinitHomeOnboardingCellNotifications,
  InfinitHomeOnboardingCellBackground,
  InfinitHomeOnboardingCellPeerSent,
  InfinitHomeOnboardingCellSelfSent,
  InfinitHomeOnboardingCellGhostSent,
};

@interface InfinitHomeOnboardingItem : NSObject

@property (nonatomic, readonly) InfinitHomeOnboardingCellType type;

+ (instancetype)initWithType:(InfinitHomeOnboardingCellType)type;

@end
