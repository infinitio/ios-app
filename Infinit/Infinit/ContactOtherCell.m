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
  
  self.avatar_image_view.layer.cornerRadius = self.avatar_image_view.frame.size.height/2;
  self.invite_button.layer.cornerRadius = 4.0f;
  self.invite_button.layer.borderWidth = 1.0f;
  self.invite_button.layer.borderColor = ([[[UIColor colorWithRed:133/255.0 green:133/255.0 blue:133/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  self.invite_button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:13.5];
}

- (void)prepareForReuse
{
  self.name_label.text = nil;
  self.info_label.text = nil;
  self.avatar_image_view.image = nil;
}

@end
