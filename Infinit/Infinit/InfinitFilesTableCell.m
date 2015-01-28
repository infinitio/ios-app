//
//  InfinitFilesTableCell.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesTableCell.h"

#import "InfinitColor.h"

#import "UIImage+Rounded.h"

#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitFilesTableCell ()

@end

@implementation InfinitFilesTableCell

- (void)awakeFromNib
{
  self.duration_label.layer.shadowOpacity = 1.0f;
  self.duration_label.layer.shadowColor = [InfinitColor colorWithGray:0 alpha:0.5f].CGColor;
  self.duration_label.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  self.duration_label.layer.shadowRadius = 2.0f;
}

- (void)configureCellWithFile:(InfinitFileModel*)file
{
  self.name_label.text = file.name;
  self.duration_label.hidden = YES;
  if (file.duration > 0)
  {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"m:ss";
    self.duration_label.text =
      [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:file.duration]];
    self.duration_label.hidden = NO;
  }
  self.icon_view.image = [file.thumbnail roundedMaskWithCornerRadius:3.0f];
  self.info_label.text =
    [NSString stringWithFormat:@"%@", [InfinitDataSize fileSizeStringFrom:file.size]];
}

- (void)configureCellWithFolder:(InfinitFolderModel*)folder
{
  self.name_label.text = folder.name;
  NSString* file_size = [InfinitDataSize fileSizeStringFrom:folder.size];
  self.info_label.text = [NSString stringWithFormat:@"%@ – %@", folder.sender_name, file_size];
  self.icon_view.image = [folder.thumbnail roundedMaskWithCornerRadius:3.0f];
  self.duration_label.hidden = YES;
  if (folder.files.count == 1)
  {
    InfinitFileModel* file = folder.files[0];
    if (file.duration > 0)
    {
      NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"m:ss";
      self.duration_label.text =
        [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:file.duration]];
      self.duration_label.hidden = NO;
    }
  }
}

@end
