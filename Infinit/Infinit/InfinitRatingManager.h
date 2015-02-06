//
//  InfinitRatingManager.h
//  Infinit
//
//  Created by Christopher Crone on 05/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitRatingManager : NSObject

@property (nonatomic, readonly) BOOL show_transaction_rating;

+ (instancetype)sharedInstance;

- (void)doneRating;

@end
