//
//  InfinitInvitationOverlayTableViewCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInvitationOverlayTableViewCell.h"

#import <Gap/InfinitColor.h>

static NSDictionary* _detail_attrs = nil;
static NSDictionary* _title_attrs = nil;

static UIImage* _email_icon = nil;
static UIImage* _phone_icon = nil;

@implementation InfinitInvitationOverlayTableViewCell

- (void)prepareForReuse
{
  [super prepareForReuse];
  [self.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
  self.button.enabled = YES;
}

- (void)dealloc
{
  [self.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.button.layer.cornerRadius = floor(self.button.bounds.size.height / 2.0f);
  self.button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.button.titleLabel.minimumScaleFactor = 0.5f;
  if (_detail_attrs == nil)
  {
    _detail_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular"
                                                           size:14.0f],
                      NSForegroundColorAttributeName: [InfinitColor colorWithGray:172]};
  }
  if (_title_attrs == nil)
  {
    _title_attrs =
      @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:14.0f],
        NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73]};
  }
  self.backgroundColor = [UIColor clearColor];
  self.backgroundView = [UIView new];
}

- (void)setupWithEmail:(NSString*)email
{
  _email = YES;
  _phone = NO;
  NSAttributedString* attr_title = [self stringFromTitle:NSLocalizedString(@"EMAIL", nil)
                                                  detail:email];
  [self.button setAttributedTitle:attr_title forState:UIControlStateNormal];
  if (_email_icon == nil)
  {
    UIImageRenderingMode orignal = UIImageRenderingModeAlwaysOriginal;
    _email_icon = [[UIImage imageNamed:@"icon-invite-email"] imageWithRenderingMode:orignal];
  }
  [self.button setImage:_email_icon forState:UIControlStateNormal];
}

- (void)setupWithPhoneNumber:(NSString*)phone
{
  _email = NO;
  _phone = YES;
  NSAttributedString* attr_title = [self stringFromTitle:NSLocalizedString(@"SMS", nil)
                                                  detail:phone];
  [self.button setAttributedTitle:attr_title forState:UIControlStateNormal];
  if (_phone_icon == nil)
  {
    UIImageRenderingMode orignal = UIImageRenderingModeAlwaysOriginal;
    _phone_icon = [[UIImage imageNamed:@"icon-invite-sms"] imageWithRenderingMode:orignal];
  }
  [self.button setImage:_phone_icon forState:UIControlStateNormal];
}

#pragma mark - Helpers

- (NSAttributedString*)stringFromTitle:(NSString*)title
                                detail:(NSString*)detail
{
  NSMutableAttributedString* res = [[NSMutableAttributedString alloc] initWithString:title
                                                                           attributes:_title_attrs];
  NSString* detail_str = [NSString stringWithFormat:@" (%@)", detail];
  [res appendAttributedString:[[NSAttributedString alloc] initWithString:detail_str
                                                              attributes:_detail_attrs]];
  return res;
}

@end
