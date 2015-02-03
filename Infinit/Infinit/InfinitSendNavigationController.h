//
//  InfinitSendNavigationController.h
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContact.h"
#import "InfinitPortraitNavigationController.h"

@interface InfinitSendNavigationController : InfinitPortraitNavigationController

@property (nonatomic, copy, readwrite) InfinitContact* recipient;

- (void)resetSendViews;

@end
