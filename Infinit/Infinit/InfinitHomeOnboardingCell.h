//
//  InfinitHomeOnboardingCell.h
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitHomeAbstractCell.h"
#import "InfinitHomeOnboardingItem.h"

@interface InfinitHomeOnboardingCell : InfinitHomeAbstractCell

@property (nonatomic, readonly) InfinitHomeOnboardingCellType type;

- (void)setType:(InfinitHomeOnboardingCellType)type
       withText:(NSString*)text
      grayRange:(NSRange)gray_range
  numberOfLines:(NSInteger)lines;

@end
