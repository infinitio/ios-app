//
//  InfinitMetricsManager.h
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitUIMetrics.h"

@interface InfinitMetricsManager : NSObject

+ (void)sendMetric:(InfinitUIEvents)event
            method:(InfinitUIMethods)method;

+ (void)sendMetric:(InfinitUIEvents)event
            method:(InfinitUIMethods)method
        additional:(NSDictionary*)additional;

@end
