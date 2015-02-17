//
//  InfinitSendGalleryCell.m
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitSendGalleryCell.h"

#import "InfinitColor.h"

@implementation InfinitSendGalleryCell

- (void)prepareForReuse
{
  self.thumbnail_view.image = nil;
  self.black_layer.hidden = YES;
  self.video_duration = 0.0f;
}

#pragma mark - General

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  self.black_layer.hidden = !selected;
  if (selected)
    self.details_view.backgroundColor = [UIColor clearColor];
  else
    self.details_view.backgroundColor = [InfinitColor colorWithGray:0 alpha:0.47f];
}

- (void)setVideo_duration:(double)duration
{
  if (duration == 0.0f)
  {
    self.details_view.hidden = YES;
    self.duration_label.text = nil;
    return;
  }
  self.details_view.hidden = NO;
  self.duration_label.text = [self stringFromDuration:duration];
}

#pragma mark - Helpers

- (NSString*)stringFromDuration:(NSTimeInterval)duration
{
  NSInteger ti = (NSInteger)duration;
  NSInteger seconds = ti % 60;
  NSInteger minutes = (ti / 60) % 60;
  NSInteger hours = (ti / 3600);
  if (ti >= 60 * 60)
    return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
  else
    return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
}

@end
