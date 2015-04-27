//
//  InfinitSendDeviceCell.m
//  Infinit
//
//  Created by Christopher Crone on 09/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendDeviceCell.h"

@implementation InfinitSendDeviceCell

- (void)setupForContact:(InfinitContact*)contact
{
  super.contact = contact;
  self.name_label.text = contact.device_name;
  self.device_type_view.image = [self typeImageFrom:contact.device.type];
  self.avatar_view.image = [self avatarFrom:contact.device.type];
}

- (UIImage*)typeImageFrom:(InfinitDeviceType)type
{
  switch (type)
  {
    case InfinitDeviceTypeAndroid:
      return [UIImage imageNamed:@"icon-device-android"];
    case InfinitDeviceTypeiPad:
    case InfinitDeviceTypeiPhone:
    case InfinitDeviceTypeiPod:
      return [UIImage imageNamed:@"icon-device-ios"];
    case InfinitDeviceTypeMacLaptop:
      return [UIImage imageNamed:@"icon-device-mac"];

    default:
      return [UIImage imageNamed:@"icon-device-windows"];
  }
}

- (UIImage*)avatarFrom:(InfinitDeviceType)type
{
  switch (type)
  {
    case InfinitDeviceTypeAndroid:
      return [UIImage imageNamed:@"icon-device-android-avatar"];
    case InfinitDeviceTypeiPad:
    case InfinitDeviceTypeiPhone:
    case InfinitDeviceTypeiPod:
      return [UIImage imageNamed:@"icon-device-ios-avatar"];
    case InfinitDeviceTypeMacLaptop:
    case InfinitDeviceTypeMacDesktop:
      return [UIImage imageNamed:@"icon-device-mac-avatar"];

    default:
      return [UIImage imageNamed:@"icon-device-windows-avatar"];
  }
}

@end
