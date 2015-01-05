//
//  HomeSmallCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "HomeSmallCollectionViewCell.h"

@implementation HomeSmallCollectionViewCell

- (void)awakeFromNib
{
  self.imageView.layer.cornerRadius = self.imageView.frame.size.height/2;
}

- (void)prepareForReuse
{
  self.notificationLabel.text = nil;
  self.imageView.image = nil;
}

@end
