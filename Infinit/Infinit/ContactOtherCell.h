//
//  ContactOtherCell.h
//  Infinit
//
//  Created by Michael Dee on 12/26/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactOtherCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@end
