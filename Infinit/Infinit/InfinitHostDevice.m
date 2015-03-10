//
//  InfinitHostDevice.m
//  Infinit
//
//  Created by Christopher Crone on 21/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHostDevice.h"

#import <sys/types.h>
#import <sys/sysctl.h>
#import <mach/machine.h>

@import MessageUI;

@implementation InfinitHostDevice

#pragma mark - CPU

+ (InfinitCPUTypes)deviceCPU
{
  size_t size;
  cpu_type_t type;
  cpu_subtype_t subtype;
  size = sizeof(type);
  sysctlbyname("hw.cputype", &type, &size, NULL, 0);

  size = sizeof(subtype);
  sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);

  // values for cputype and cpusubtype defined in mach/machine.h
  if (type == CPU_TYPE_X86)
  {
    return InfinitCPUType_x86;
  }
  else if (type == CPU_TYPE_ARM)
  {
    switch(subtype)
    {
      case CPU_SUBTYPE_ARM_V7:
        return InfinitCPUType_ARM_v7;
      case CPU_SUBTYPE_ARM_V7F:
        return InfinitCPUType_ARM_v7f;
      case CPU_SUBTYPE_ARM_V7S:
        return InfinitCPUType_ARM_v7s;

      default:
        return InfinitCPUType_ARM_Unknown;
    }
  }
  else if (type == CPU_TYPE_ARM64)
  {
    switch (subtype)
    {
      case CPU_SUBTYPE_ARM64_V8:
        return InfinitCPUType_ARM64_v8;

      default:
        return InfinitCPUType_ARM64_Unknown;
    }
  }
  else
  {
    return InfinitCPUType_Unknown;
  }
}

+ (NSString*)deviceCPUDescription
{
  switch ([self deviceCPU])
  {
    case InfinitCPUType_x86:
      return @"x86";
    case InfinitCPUType_ARM_Unknown:
      return @"ARM_Unknown";
    case InfinitCPUType_ARM_v7:
      return @"ARM_v7";
    case InfinitCPUType_ARM_v7f:
      return @"ARM_v7f";
    case InfinitCPUType_ARM_v7s:
      return @"ARM_v7s";
    case InfinitCPUType_ARM64_Unknown:
      return @"ARM64_Unknown";
    case InfinitCPUType_ARM64_v8:
      return @"ARM64_v8";

    default:
      return @"Unknown";
  }
}

#pragma mark - Screen

+ (CGFloat)screenScale
{
  return [UIScreen mainScreen].scale;
}

+ (BOOL)smallScreen
{
  if ([UIScreen mainScreen].bounds.size.height < 568.0f)
    return YES;
  return NO;
}

#pragma mark - Messaging

+ (BOOL)canSendSMS
{
  return [MFMessageComposeViewController canSendText];
}

#pragma mark - OS Version

+ (BOOL)iOS7
{
  NSComparisonResult res = [[UIDevice currentDevice].systemVersion compare:@"8.0"
                                                                   options:NSNumericSearch];
  return (res == NSOrderedAscending);
}

@end
