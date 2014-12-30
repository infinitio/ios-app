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
  _imageView.layer.cornerRadius = _imageView.frame.size.height/2;
}

@end
