//
//  InfinitSendGalleryCell.m
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitSendGalleryCell.h"

#import "InfinitColor.h"

@implementation InfinitSendGalleryCell

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  self.black_layer.hidden = !selected;
}

- (void)prepareForReuse
{
  self.image_view.image = nil;
  self.duration_label.text = nil;
  self.black_layer.hidden = YES;
}

@end
