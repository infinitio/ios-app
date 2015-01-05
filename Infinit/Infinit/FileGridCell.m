//
//  FileGridCell.m
//  Infinit
//
//  Created by Michael Dee on 12/22/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "FileGridCell.h"

@implementation FileGridCell

- (void)awakeFromNib
{
  
}

- (void)prepareForReuse
{
  self.image_view.image = nil;
}

@end
