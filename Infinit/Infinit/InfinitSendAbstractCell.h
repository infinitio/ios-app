//
//  InfinitSendAbstractCell.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContact.h"
#import "InfinitCheckView.h"

@interface InfinitSendAbstractCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet InfinitCheckView* check_view;
@property (nonatomic, weak) IBOutlet UILabel* name_label;

@property (nonatomic, weak, readwrite) InfinitContact* contact;

@end
