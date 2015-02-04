//
//  InfinitSendContactCell.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitSendAbstractCell.h"

@interface InfinitSendContactCell : InfinitSendAbstractCell

@property (nonatomic, weak) IBOutlet UILabel* details_label;
@property (nonatomic, weak) IBOutlet UILabel* letter_label;

@end
