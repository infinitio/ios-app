//
//  InfinitContact.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

#import "NSString+email.h"

@interface InfinitContact ()

@property (readonly) BOOL inited_with_infinit_user;

@end

@implementation InfinitContact

#pragma mark - Init

- (id)initWithABRecord:(ABRecordRef)record
{
  if (self = [super init])
  {
    _inited_with_infinit_user = NO;
    _infinit_user = nil;

    ABMultiValueRef email_property = ABRecordCopyValue(record, kABPersonEmailProperty);
    _emails = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(email_property);
    CFRelease(email_property);
    NSMutableArray* temp_emails = [NSMutableArray array];
    for (NSString* email in self.emails)
    {
      if (email.isEmail)
        [temp_emails addObject:email];
    }
    _emails = [temp_emails copy];
    ABMultiValueRef phone_property = ABRecordCopyValue(record, kABPersonPhoneProperty);
    _phone_numbers = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(phone_property);
    CFRelease(phone_property);

    if (self.emails.count == 0 && self.phone_numbers.count == 0)
      return nil;

    if (self.emails.count == 0)
      _emails = nil;

    if (self.phone_numbers.count == 0)
      _phone_numbers = nil;

    NSString* first_name =
      (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* surname =
      (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    NSMutableString* name_str = [[NSMutableString alloc] init];
    if (first_name.length > 0)
    {
      [name_str appendString:first_name];
      if (surname.length > 0)
        [name_str appendFormat:@" %@", surname];
    }
    else if (surname.length > 0)
    {
      [name_str appendString:surname];
    }
    else
    {
      if (self.emails.count > 0)
        [name_str appendString:self.emails[0]];
      else if (self.phone_numbers.count > 0)
        [name_str appendString:self.phone_numbers[0]];
      else
        [name_str appendString:NSLocalizedString(@"Unknown", nil)];
    }
    _first_name = first_name;
    _fullname = [NSString stringWithString:name_str];

    NSData* image_data =
      (__bridge_transfer NSData*)(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
    _avatar = [UIImage imageWithData:image_data scale:1.0f];
    if (self.avatar == nil)
      [self generateAvatarWithFirstName:first_name surname:surname];
    _selected_email_index = NSNotFound;
    _selected_phone_index = NSNotFound;
    _device = nil;
  }
  return self;
}

- (id)initWithEmail:(NSString*)email_
{
  if (self = [super init])
  {
    NSString* email =
      [email_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
    _inited_with_infinit_user = NO;
    _infinit_user = nil;
    _avatar = nil;
    _emails = @[email];
    _selected_email_index = NSNotFound;
    _selected_phone_index = NSNotFound;
    _fullname = email;
    _first_name = email;
    _phone_numbers = nil;
    _device = nil;
  }
  return self;
}

- (id)initWithInfinitUser:(InfinitUser*)user
{
  return [[InfinitContact alloc] initWithInfinitUser:user andDevice:nil];
}

- (id)initWithInfinitUser:(InfinitUser*)user
                andDevice:(InfinitDevice*)device
{
  if (self = [super init])
  {
    _inited_with_infinit_user = YES;
    _infinit_user = user;
    _avatar = user.avatar;
    _emails = nil;
    if (user.is_self)
      _fullname = NSLocalizedString(@"Me", nil);
    else
      _fullname = user.fullname;
    NSArray* temp = [self.fullname componentsSeparatedByString:@" "];
    if (temp.count > 0 && [temp[0] length] > 0)
      _first_name = temp[0];
    else
      _first_name = self.fullname;
    _phone_numbers = nil;
    _selected_email_index = NSNotFound;
    _selected_phone_index = NSNotFound;
    _device = device;
  }
  return self;
}

#pragma mark - General

- (void)updateAvatar
{
  if (self.infinit_user == nil)
    return;
  self.avatar = self.infinit_user.avatar;
}

- (void)generateAvatarWithFirstName:(NSString*)first_name
                            surname:(NSString*)surname
{
  UIColor* fill = [InfinitColor colorWithRed:202 green:217 blue:223];
  CGFloat scale = [InfinitHostDevice screenScale];
  CGRect rect = CGRectMake(0.0f, 0.0f, 40.0f * scale, 40.0f * scale);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [fill setFill];
  CGContextFillRect(context, rect);
  [[UIColor whiteColor] set];
  NSMutableString* text = [[NSMutableString alloc] init];
  if (first_name.length > 0)
  {
    [text appendFormat:@"%c", [first_name characterAtIndex:0]];
    if (surname.length > 0)
      [text appendFormat:@"%c", [surname characterAtIndex:0]];
  }
  else if (self.emails.count > 0)
  {
    [text appendString:@"@"];
  }
  else
  {
    [text appendString:@" "];
  }
  NSDictionary* attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light"
                                                               size:(17.0f * scale)],
                          NSForegroundColorAttributeName: [UIColor whiteColor]};
  NSAttributedString* str = [[NSAttributedString alloc] initWithString:text attributes:attrs];
  [str drawAtPoint:CGPointMake(round((rect.size.width - str.size.width) / 2.0f),
                               round((rect.size.height - str.size.height) / 2.0f))];
  self.avatar = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
}

#pragma mark - Device Name

- (NSString*)device_name
{
  if (self.device == nil)
    return nil;
  return self.device.friendly_name;
}

#pragma mark - Helpers

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitContact* other = (InfinitContact*)object;
  if (self.infinit_user && other.infinit_user && [self.infinit_user isEqual:other.infinit_user])
  {
    if (self.infinit_user.is_self)
    {
      if ([self.device isEqual:other.device])
        return YES;
    }
    else
    {
      return YES;
    }
  }
  if (self.emails && other.emails && [self.emails isEqualToArray:other.emails])
    return YES;
  if (self.phone_numbers && other.phone_numbers &&
      [self.phone_numbers isEqualToArray:other.phone_numbers])
    return YES;
  return NO;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> emails: %@\rnumbers: %@\rinfinit:%@\rdevice: %@",
          self.fullname, self.emails, self.phone_numbers, self.infinit_user, self.device];
}

#pragma mark - Search

- (BOOL)containsSearchString:(NSString*)search_string
{
  NSUInteger score = 0;
  NSString* trimmed_string = search_string;
    [search_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSArray* components = [trimmed_string componentsSeparatedByString:@" "];
  for (NSString* component in components)
  {
    if ([self source:self.fullname containsString:component] ||
        [self emails:self.emails containString:component] ||
        (self.infinit_user != nil &&
         [self source:self.infinit_user.handle containsString:component]) ||
        (self.device != nil && [self source:self.device_name containsString:component]))
    {
      score++;
    }
  }
  if (score == components.count)
    return YES;
  return NO;
}

- (BOOL)source:(NSString*)source
containsString:(NSString*)string
{
  if ([source rangeOfString:string options:NSCaseInsensitiveSearch].location == NSNotFound)
    return NO;
  return YES;
}

- (BOOL)emails:(NSArray*)emails
 containString:(NSString*)string
{
  if (emails == nil)
    return NO;
  for (NSString* email in emails)
  {
    if ([self source:email containsString:string])
      return YES;
  }
  return NO;
}

#pragma mark - NSObject

- (id)initCopy:(InfinitContact*)original
{
  if (self = [super init])
  {
    _avatar = [original.avatar copy];
    _emails = [original.emails copy];
    _first_name = [original.first_name copy];
    _fullname = [original.fullname copy];
    _infinit_user = original.infinit_user;
    _phone_numbers = [original.phone_numbers copy];
    _selected_email_index = original.selected_email_index;
    _selected_phone_index = original.selected_phone_index;
  }
  return self;
}

- (id)copyWithZone:(NSZone*)zone
{
  return [[InfinitContact allocWithZone:zone] initCopy:self];
}

@end
