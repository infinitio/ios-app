//
//  NSData+Conversion.m
//  Infinit
//
//  Created by Christopher Crone on 07/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "NSData+Conversion.h"

@implementation NSData (infinit_Conversion)

- (NSString*)infinit_hexadecimalString
{
  const unsigned char* buffer = (const unsigned char*)self.bytes;
  if (!buffer)
    return @"";

  NSMutableString* res = [[NSMutableString alloc] init];
  for (int i = 0; i < self.length; ++i)
    [res appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];

  return [NSString stringWithString:res];
}

@end
