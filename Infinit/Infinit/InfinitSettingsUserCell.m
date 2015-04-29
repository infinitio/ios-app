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

- (void)configureWithUser:(InfinitUser*)user
{
  self.name_label.text = user.fullname;
  self.background_view.image = [user.avatar applyDarkEffect];
  self.avatar_view.image = [user.avatar infinit_circularMaskOfSize:self.avatar_view.frame.size];
  self.clipsToBounds = YES;
}

@end
