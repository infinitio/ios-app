//
//  InfinitContactAddressBook.m
//  Infinit
//
//  Created by Christopher Crone on 02/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactAddressBook.h"

#import "InfinitHostDevice.h"

#import <Gap/InfinitColor.h>
#import <Gap/NSString+email.h>
#import <Gap/NSString+PhoneNumber.h>

@implementation InfinitContactAddressBook

#pragma mark - Init

- (instancetype)initWithABRecord:(ABRecordRef)record
{
  ABMultiValueRef email_property = ABRecordCopyValue(record, kABPersonEmailProperty);
  NSArray* temp_emails = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(email_property);
  CFRelease(email_property);
  NSMutableArray* res_emails = [NSMutableArray array];
  for (NSString* email in temp_emails)
  {
    if (email.infinit_isEmail)
      [res_emails addObject:email];
  }
  ABMultiValueRef phone_property = ABRecordCopyValue(record, kABPersonPhoneProperty);
  NSArray* temp_numbers = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(phone_property);
  CFRelease(phone_property);
  NSMutableArray* res_numbers = [NSMutableArray array];
  for (NSString* number in temp_numbers)
  {
    if (number.infinit_isPhoneNumber)
    {
      [res_numbers addObject:number];
    }
    else if ([number rangeOfString:@"00"].location == 0)
    {
      NSString* new_number = [number stringByReplacingCharactersInRange:NSMakeRange(0, 2)
                                                             withString:@"+"];
      if (new_number.infinit_isPhoneNumber)
        [res_numbers addObject:new_number];
    }
  }
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
    if (res_emails.count > 0)
      [name_str appendString:res_emails[0]];
    else if (res_numbers.count > 0)
      [name_str appendString:res_numbers[0]];
    else
      [name_str appendString:NSLocalizedString(@"Unknown", nil)];
  }
  NSData* image_data =
    (__bridge_transfer NSData*)(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
  UIImage* avatar = [UIImage imageWithData:image_data scale:1.0f];
  if (avatar == nil)
    avatar = [self generateAvatarWithFirstName:first_name surname:surname];

  if (self = [super initWithAvatar:avatar firstName:first_name fullname:name_str])
  {
    _address_book_id = ABRecordGetRecordID(record);
    _emails = [res_emails copy];
    _phone_numbers = [res_numbers copy];
    if (self.emails.count == 0 && self.phone_numbers.count == 0)
      return nil;

    if (self.emails.count == 0)
      _emails = nil;

    if (self.phone_numbers.count == 0)
      _phone_numbers = nil;

    _selected_email_index = NSNotFound;
    _selected_phone_index = NSNotFound;
  }
  return self;
}

+ (instancetype)contactWithABRecord:(ABRecordRef)record
{
  return [[self alloc] initWithABRecord:record];
}

#pragma mark - InfinitContact

- (BOOL)containsSearchString:(NSString*)search_string
{
  NSUInteger score = 0;
  NSString* trimmed_string = search_string;
  [search_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSArray* components = [trimmed_string componentsSeparatedByString:@" "];
  for (NSString* component in components)
  {
    if ([super containsSearchString:search_string] ||
        [self emails:self.emails containString:component])
    {
      score++;
    }
  }
  if (score == components.count)
    return YES;
  return NO;
}

#pragma mark - NSObject

- (instancetype)copyWithZone:(NSZone*)zone
{
  InfinitContactAddressBook* res = [[[self class] allocWithZone:zone] init];
  res->_address_book_id = self.address_book_id;
  res->_emails = [self.emails copy];
  res->_phone_numbers = [self.phone_numbers copy];
  res->_selected_email_index = self.selected_email_index;
  res->_selected_phone_index = self.selected_phone_index;
  return res;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> emails: %@\rnumbers: %@",
          self.fullname, self.emails, self.phone_numbers];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitContactAddressBook* other = (InfinitContactAddressBook*)object;
  if (self.emails && other.emails && [self.emails isEqualToArray:other.emails])
    return YES;
  if (self.phone_numbers && other.phone_numbers &&
      [self.phone_numbers isEqualToArray:other.phone_numbers])
    return YES;
  return NO;
}

#pragma mark - Helpers

- (UIImage*)generateAvatarWithFirstName:(NSString*)first_name
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
  UIImage* res = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return res;
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

@end
