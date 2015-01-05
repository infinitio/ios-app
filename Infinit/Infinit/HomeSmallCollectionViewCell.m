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
  self.image_view.layer.cornerRadius = self.image_view.frame.size.height/2;
}

- (void)prepareForReuse
{
  self.notification_label.text = nil;
  self.image_view.image = nil;
}

@end
