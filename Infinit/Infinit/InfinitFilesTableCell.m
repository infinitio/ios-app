//
//  InfinitFilesTableCell.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesTableCell.h"

#import "UIImage+Rounded.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/NSNumber+DataSize.h>

@interface InfinitFilesTableCell ()

@end

@implementation InfinitFilesTableCell

- (void)awakeFromNib
{
  self.duration_label.layer.shadowOpacity = 1.0f;
  self.duration_label.layer.shadowColor = [InfinitColor colorWithGray:0 alpha:0.5f].CGColor;
  self.duration_label.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  self.duration_label.layer.shadowRadius = 2.0f;
  UIView* background = [[UIView alloc] initWithFrame:self.bounds];
  background.backgroundColor = [UIColor whiteColor];
  self.selectedBackgroundView = background;
}

- (void)configureCellWithFile:(InfinitFileModel*)file
{
  self.name_label.text = file.name;
  self.duration_label.hidden = YES;
  if (file.duration > 0)
  {
    self.duration_label.text = [self stringFromDuration:file.duration];
    self.duration_label.hidden = NO;
  }
  self.icon_view.image = [file.thumbnail infinit_roundedMaskOfSize:self.icon_view.bounds.size
                                                      cornerRadius:3.0f];
  self.info_label.text = [NSString stringWithFormat:@"%@", file.size.infinit_fileSize];
}

- (void)configureCellWithFolder:(InfinitFolderModel*)folder
{
  self.name_label.text = folder.name;
  self.info_label.text =
    [NSString stringWithFormat:@"%@ – %@", folder.sender_name, folder.size.infinit_fileSize];
  self.icon_view.image = [folder.thumbnail infinit_roundedMaskOfSize:self.icon_view.bounds.size
                                                        cornerRadius:3.0f];
  self.duration_label.hidden = YES;
  if (folder.files.count == 1)
  {
    InfinitFileModel* file = folder.files[0];
    if (file.duration > 0)
    {
      self.duration_label.text = [self stringFromDuration:file.duration];
      self.duration_label.hidden = NO;
    }
  }
}

#pragma mark - Helpers

- (NSString*)stringFromDuration:(NSTimeInterval)duration
{
  NSInteger ti = (NSInteger)duration;
  NSInteger seconds = ti % 60;
  NSInteger minutes = (ti / 60) % 60;
  NSInteger hours = (ti / 3600);
  if (ti < 60 * 60)
    return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
  else
    return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

@end
