//
//  InfinitHomePeerTransactionFileCell.m
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomePeerTransactionFileCell.h"

@implementation InfinitHomePeerTransactionFileCell

- (void)setFilename:(NSString*)filename
{
  self.file_name_label.text = filename;
}

- (void)setThumbnail:(UIImage*)thumbnail
{
  self.file_icon_view.image = thumbnail;
}

@end
