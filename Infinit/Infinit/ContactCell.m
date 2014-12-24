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
  
  self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height/2;
  
  self.favButton.layer.cornerRadius = 4.0f;
  self.filesButton.layer.cornerRadius = 4.0f;
  self.sendButton.layer.cornerRadius = 4.0f;

}

- (void)prepareForReuse
{
  self.nameLabel.text = nil;
}

@end
