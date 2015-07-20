//
//  ALAsset+Date.m
//  Infinit
//
//  Created by Christopher Crone on 14/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "ALAsset+Date.h"

@implementation ALAsset (infinit_Date)

- (NSDate*)date
{
  return [self valueForProperty:ALAssetPropertyDate];
}

@end
