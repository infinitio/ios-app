//
//  InfinitHomePeerTransactionMoreFilesCell.m
//  Infinit
//
//  Created by Christopher Crone on 25/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomePeerTransactionMoreFilesCell.h"

#import <Gap/InfinitColor.h>

@interface InfinitHomePeerTransactionMoreFilesCell ()

@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* files_label;

@end

@implementation InfinitHomePeerTransactionMoreFilesCell

static UIImage* _icon_image = nil;

- (void)awakeFromNib
{
  if (_icon_image == nil)
  {
    UIGraphicsBeginImageContextWithOptions(self.icon_view.bounds.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath* shape = [UIBezierPath bezierPathWithRoundedRect:self.icon_view.bounds
                                                     cornerRadius:2.0f];
    CGContextAddPath(context, shape.CGPath);
    [[InfinitColor colorWithGray:245] set];
    CGContextFillPath(context);
    _icon_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }
  self.icon_view.image = _icon_image;
}

- (void)setCount:(NSUInteger)count
{
  self.icon_view.image = _icon_image;
  self.files_label.text = [NSString stringWithFormat:@"+%lu", (unsigned long)count];
}

@end
