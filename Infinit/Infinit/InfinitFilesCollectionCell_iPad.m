//
//  InfinitFilesCollectionCell_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesCollectionCell_iPad.h"

#import "InfinitFilePreview.h"
#import "InfinitTime.h"

@import AVFoundation;

@implementation InfinitFilesCollectionCell_iPad

- (void)awakeFromNib
{
  self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)configureForFile:(InfinitFileModel*)file
{
  CGSize size = self.thumbnail_view.bounds.size;
  UIImage* thumb = [InfinitFilePreview previewForPath:file.path ofSize:size crop:NO];
  self.thumbnail_view.image = thumb;
  self.h_constraint.constant = thumb.size.height;
  self.w_constraint.constant = thumb.size.width;
  if (file.type == InfinitFileTypeVideo)
  {
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:file.path] 
                                            options:nil];
    self.duration_label.text = [InfinitTime stringFromDuration:CMTimeGetSeconds(asset.duration)];
    self.video_view.hidden = NO;
  }
  else
  {
    self.video_view.hidden = YES;
  }
}

@end
