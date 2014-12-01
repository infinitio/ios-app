//
//  TabBarBadgeLabel.m
//  Infinit
//
//  Created by Michael Dee on 11/27/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "TabBarBadgeLabel.h"

@implementation TabBarBadgeLabel

- (id)initWithFrame:(CGRect)frame
             onItem:(NSInteger)itemNumber
          withBadge:(NSInteger)badgeCount
{
    frame.origin.x = 60 + 50 * itemNumber;
    frame.origin.y = 5;
    
    self = [super initWithFrame:frame];
    if(self)
    {
        self.layer.cornerRadius = self.frame.size.height/2;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor redColor];
        self.textColor = [UIColor whiteColor];
        self.text = [NSString stringWithFormat:@"%ld",(long)badgeCount];
        self.textAlignment = NSTextAlignmentCenter;
        self.font = [UIFont boldSystemFontOfSize:12];
    }
    return self;
}


@end
