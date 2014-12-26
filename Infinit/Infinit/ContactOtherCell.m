//
//  ContactOtherCell.m
//  Infinit
//
//  Created by Michael Dee on 12/26/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "ContactOtherCell.h"

@implementation ContactOtherCell

- (void)awakeFromNib {
  // Initialization code
  
  self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height/2;

  self.inviteButton.layer.cornerRadius = 4.0f;
  self.inviteButton.layer.borderWidth = 1.0f;
  self.inviteButton.layer.borderColor = ([[[UIColor colorWithRed:133/255.0 green:133/255.0 blue:133/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  self.inviteButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:13.5];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
