//
//  InfinitMetricsManager.h
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitUIMetrics.h"

#import <surface/gap/enums.hh>

@interface InfinitMetricsManager : NSObject

+ (void)sendMetric:(InfinitUIEvents)event
            method:(InfinitUIMethods)method;

+ (void)sendMetric:(InfinitUIEvents)event
            method:(InfinitUIMethods)method
        additional:(NSDictionary*)additional;

+ (void)sendMetricGhostSMSSent:(BOOL)success
                          code:(NSString*)code
                    failReason:(NSString*)fail_reason;

+ (void)sendMetricGhostReminder:(BOOL)success
                         method:(gap_InviteMessageMethod)method
                           code:(NSString*)code 
                     failReason:(NSString*)fail_reason;

@end
