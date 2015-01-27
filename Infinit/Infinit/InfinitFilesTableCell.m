//
//  InfinitFilesTableCell.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesTableCell.h"

#import "UIImage+Rounded.h"

#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitFilesTableCell ()

@end

@implementation InfinitFilesTableCell

- (void)configureCellWithFile:(InfinitFileModel*)file
{
  self.name_label.text = file.name;
  self.icon_view.image = [file.thumbnail roundedMaskWithCornerRadius:3.0f];
  self.info_label.text =
    [NSString stringWithFormat:@"%@", [InfinitDataSize fileSizeStringFrom:file.size]];
}

- (void)configureCellWithFolder:(InfinitFolderModel*)folder
{
  self.name_label.text = folder.name;
  NSString* file_size = [InfinitDataSize fileSizeStringFrom:folder.size];
  self.info_label.text = [NSString stringWithFormat:@"%@ – %@", file_size, folder.sender_name];
  self.icon_view.image = [folder.thumbnail roundedMaskWithCornerRadius:3.0f];
}

@end
