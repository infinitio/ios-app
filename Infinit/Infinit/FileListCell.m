//
//  FileListCell.m
//  Infinit
//
//  Created by Michael Dee on 12/22/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "FileListCell.h"

@implementation FileListCell

- (void)awakeFromNib
{
  

}

- (void)prepareForReuse
{
  self.from_label.text = nil;
  self.name_label.text = nil;
  self.image_view.image = nil;
}

@end
