//
//  HomeLargeCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "HomeLargeCollectionViewCell.h"

@implementation HomeLargeCollectionViewCell

- (void)awakeFromNib
{
  _filesLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:36];
  
  _imageView.layer.cornerRadius = _imageView.frame.size.height/2;
  
}

@end
