//
//  InfinitCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitGalleryViewCell.h"

@implementation InfinitGalleryViewCell


- (id)initWithFrame:(CGRect)frame
{
  if ([super initWithFrame:frame])
  {
    self.image_view = [[UIImageView alloc] initWithFrame:self.contentView.bounds];

    self.black_layer = [[UIView alloc] initWithFrame:self.contentView.frame];
    self.black_layer.backgroundColor = [UIColor blackColor];
    self.black_layer.alpha = 0.75f;

    self.check_mark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-checked.png"]];
    self.check_mark.center = CGPointMake(self.frame.size.width / 2.0f,
                                         self.frame.size.height / 2.0f);

    [self.contentView addSubview:self.image_view];
    [self.contentView addSubview:self.black_layer];
    [self.contentView addSubview:self.check_mark];

    CGRect duration_frame = CGRectMake(70, 86, 40, 18);
    self.duration_label = [[UILabel alloc] initWithFrame:duration_frame];
    self.duration_label.textColor = [UIColor whiteColor];
    self.duration_label.font = [UIFont boldSystemFontOfSize:12];

    self.black_layer.hidden = YES;
    self.check_mark.hidden = YES;
  }
  return self;
}

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  self.black_layer.hidden = !selected;
  self.check_mark.hidden = !selected;
}

- (void)prepareForReuse
{
  self.image_view.image = nil;
  self.duration_label.text = nil;
}

@end
