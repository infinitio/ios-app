//
//  InfinitAccessGalleryView.m
//  Infinit
//
//  Created by Christopher Crone on 10/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitAccessGalleryView.h"

@implementation InfinitAccessGalleryView

- (void)awakeFromNib
{
  self.access_button.layer.cornerRadius = self.access_button.bounds.size.height / 2.0f;
}

@end
