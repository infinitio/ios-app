//
//  ContactCell.m
//  Infinit
//
//  Created by Michael Dee on 12/21/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "ContactCell.h"

@implementation ContactCell

-(void)awakeFromNib
{
  self.clipsToBounds = YES;
  self.avatar_image_view.layer.cornerRadius = self.avatar_image_view.frame.size.height/2;
  self.fav_button.layer.cornerRadius = 4.0f;
  self.files_button.layer.cornerRadius = 4.0f;
  self.send_button.layer.cornerRadius = 4.0f;
}

- (void)prepareForReuse
{
  self.name_label.text = nil;
  self.avatar_image_view.image = nil;
}

@end
