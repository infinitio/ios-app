//
//  InfinitHomeRatingCell.h
//  Infinit
//
//  Created by Christopher Crone on 05/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitHomeAbstractCell.h"

typedef NS_ENUM(NSUInteger, InfinitRatingCellStates)
{
  InfinitRatingCellStateFirst,
  InfinitRatingCellStateRate,
  InfinitRatingCellStateFeedback,
};

@interface InfinitHomeRatingCell : InfinitHomeAbstractCell

@property (nonatomic, weak) IBOutlet UIButton* negative_button;
@property (nonatomic, weak) IBOutlet UIButton* positive_button;

@property (nonatomic, readwrite) InfinitRatingCellStates state;

@end
