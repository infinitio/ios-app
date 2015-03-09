//
//  InfinitSendDeviceCell.h
//  Infinit
//
//  Created by Christopher Crone on 09/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendAbstractCell.h"

#import "InfinitContact.h"
#import <Gap/InfinitDevice.h>

@interface InfinitSendDeviceCell : InfinitSendAbstractCell

@property (nonatomic, weak) IBOutlet UIImageView* device_type_view;

- (void)setupForContact:(InfinitContact*)contact;

@end
