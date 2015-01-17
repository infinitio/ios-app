//
//  InfinitHomeAvatarView.h
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitHomeAvatarView : UIView

@property (nonatomic, readwrite) UIImage* image;
@property (nonatomic, readwrite) IBOutlet UIImageView* image_view;
@property (nonatomic, readwrite) CGFloat progress;
@property (nonatomic, readwrite) BOOL enable_progress;

- (void)setProgress:(CGFloat)progress
  withAnimationTime:(NSTimeInterval)duration;

@end
