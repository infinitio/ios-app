//
//  InfinitFeedbackManager.h
//  Infinit
//
//  Created by Christopher Crone on 04/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitFeedbackManager : NSObject

+ (instancetype)sharedInstance;

- (void)gotShake:(UIEvent*)event;

@end
