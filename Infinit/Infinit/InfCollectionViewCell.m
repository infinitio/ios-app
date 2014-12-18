//
//  InfCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfCollectionViewCell.h"

@implementation InfCollectionViewCell


- (id)initWithFrame:(CGRect)frame
{

  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];

    _checkMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-checked.png"]];
    _checkMark.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    _checkMark.hidden = NO;
    
    _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    
    [self.contentView addSubview:_imageView];
    [self.contentView addSubview:_checkMark];
    
    CGRect durationFrame = CGRectMake(70, 86, 40, 18);
    _durationLabel = [[UILabel alloc] initWithFrame:durationFrame];
    _durationLabel.textColor = [UIColor whiteColor];
    _durationLabel.font = [UIFont boldSystemFontOfSize:12];
  }
  return self;
}



- (void)prepareForReuse
{
  [_animator removeAllBehaviors];
  _imageView.image = nil;
  _durationLabel.text = nil;
  _checkMark.hidden = NO;
}

@end
