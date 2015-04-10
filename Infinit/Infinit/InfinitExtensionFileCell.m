//
//  InfinitExtensionFileCell.m
//  Infinit
//
//  Created by Christopher Crone on 10/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitExtensionFileCell.h"

@interface InfinitExtensionFileCell ()

@property (nonatomic, weak) IBOutlet UIImageView* file_icon_view;

@end

@implementation InfinitExtensionFileCell

- (void)setThumbnail:(UIImage*)thumbnail
{
  self.file_icon_view.image = thumbnail;
}

@end
