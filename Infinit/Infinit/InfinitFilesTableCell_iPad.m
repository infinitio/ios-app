//
//  InfinitFilesTableCell_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesTableCell_iPad.h"

#import "InfinitDataSize.h"
#import "UIImage+Rounded.h"

@implementation InfinitFilesTableCell_iPad

+ (NSString*)cell_id
{
  return @"files_table_cell_ipad";
}

+ (CGFloat)height
{
  return 60.0f;
}

- (void)awakeFromNib
{
  UIView* background = [[UIView alloc] initWithFrame:self.bounds];
  background.backgroundColor = [UIColor whiteColor];
  self.selectedBackgroundView = background;
}

- (void)configureForFile:(InfinitFileModel*)file
{
  self.thumbnail_view.image = [file.thumbnail roundedMaskOfSize:self.thumbnail_view.bounds.size
                                                   cornerRadius:3.0f];
  self.filename_label.text = file.name;
  self.info_label.text = [InfinitDataSize fileSizeStringFrom:file.size];
}

- (void)configureForFolder:(InfinitFolderModel*)folder
{
  self.thumbnail_view.image = [folder.thumbnail roundedMaskOfSize:self.thumbnail_view.bounds.size
                                                     cornerRadius:3.0f];
  self.filename_label.text = folder.name;
  NSString* size_str = [InfinitDataSize fileSizeStringFrom:folder.size];
  NSString* info = [NSString stringWithFormat:@"%@ – %@", folder.sender_name, size_str];
  self.info_label.text = info;
  if (folder.files.count > 1)
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

@end
