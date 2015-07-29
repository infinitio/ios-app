//
//  InfinitSettingsUserCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsUserCell.h"

#import "UIImage+Rounded.h"
#import "UIImage+ImageEffects.h"

@interface InfinitSettingsUserCell ()

@property (nonatomic, weak) IBOutlet UIImageView* background_view;
@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UILabel* name_label;

@end

@implementation InfinitSettingsUserCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.clipsToBounds = YES;
}

- (void)configureWithUser:(InfinitUser*)user
{
  UIImage* background = [user.avatar applyDarkEffect];
  UIImage* round_avatar = [user.avatar infinit_circularMaskOfSize:self.avatar_view.frame.size];
  dispatch_async(dispatch_get_main_queue(), ^
  {
    self.name_label.text = user.fullname;
    self.background_view.image = background;
    self.avatar_view.image = round_avatar;
  });
}

@end
