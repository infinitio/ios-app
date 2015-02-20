//
//  InfinitHomePeerTransactionFileCell.m
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomePeerTransactionFileCell.h"

#import "UIImage+Rounded.h"

@interface InfinitHomePeerTransactionFileCell ()

@property (nonatomic, weak) IBOutlet UIImageView* file_icon_view;
@property (nonatomic, weak) IBOutlet UILabel* file_name_label;

@end

@implementation InfinitHomePeerTransactionFileCell

- (void)setFilename:(NSString*)filename
{
  self.file_name_label.text = filename;
}

- (void)setThumbnail:(UIImage*)thumbnail
{
  self.file_icon_view.image = [thumbnail roundedMaskOfSize:self.file_icon_view.bounds.size
                                              cornerRadius:0.0f];
}

@end
