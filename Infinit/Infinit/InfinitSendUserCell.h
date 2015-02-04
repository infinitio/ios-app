//
//  InfinitSendUserCell.h
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitSendAbstractCell.h"

#import "InfinitContact.h"

@interface InfinitSendUserCell : InfinitSendAbstractCell

@property (nonatomic, weak) IBOutlet UIImageView* user_type_view;

- (void)updateAvatar;

@end
