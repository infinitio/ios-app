//
//  InfinitSettingsUserCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsUserCell.h"

#import "UIImage+circular.h"
#import "UIImage+ImageEffects.h"

@implementation InfinitSettingsUserCell

- (void)configureWithUser:(InfinitUser*)user
{
  self.avatar_view.image = user.avatar.circularMask;
  self.name_label.text = user.fullname;
  self.background_view.image = [user.avatar applyDarkEffect];
  self.clipsToBounds = YES;
}

@end
