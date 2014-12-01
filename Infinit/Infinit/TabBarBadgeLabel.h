//
//  TabBarBadgeLabel.h
//  Infinit
//
//  Created by Michael Dee on 11/27/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TabBarBadgeLabel : UILabel

- (id)initWithFrame:(CGRect)frame
             onItem:(NSInteger)itemNumber
          withBadge:(NSInteger)badgeCount;

@end
