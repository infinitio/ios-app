//
//  InfinitFilesOnboardingManager.m
//  Infinit
//
//  Created by Christopher Crone on 07/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesOnboardingManager.h"

#import <Gap/InfinitDirectoryManager.h>

static NSString* _file_1 = @"How To Send To Someone";
static NSString* _file_2 = @"How To Send To Self";

@implementation InfinitFilesOnboardingManager

+ (void)copyFilesForOnboarding
{
  NSString* file_1 = [[NSBundle mainBundle] pathForResource:_file_1 ofType:@"mp4"];
  NSString* file_2 = [[NSBundle mainBundle] pathForResource:_file_2 ofType:@"mp4"];
  NSString* download_dir = [InfinitDirectoryManager sharedInstance].download_directory;
  NSString* destination_1 = [download_dir stringByAppendingPathComponent:@"onboarding_1"];
  NSString* destination_2 = [download_dir stringByAppendingPathComponent:@"onboarding_2"];
  [self copyFile:file_1 toDestination:destination_1];
  [self copyFile:file_2 toDestination:destination_2];
}

+ (void)copyFile:(NSString*)path
   toDestination:(NSString*)destination
{
  NSDate* now = [NSDate date];
  NSError* error = nil;
  NSDictionary* meta_data = @{@"sender": @"onboarder",
                              @"sender_device": @"",
                              @"sender_fullname": @"Infinit",
                              @"ctime": @(now.timeIntervalSince1970),
                              @"done": @(YES)};
  [[NSFileManager defaultManager] createDirectoryAtPath:destination
                            withIntermediateDirectories:YES 
                                             attributes:nil
                                                  error:&error];
  NSString* destination_path = [destination stringByAppendingPathComponent:path.lastPathComponent];
  [[NSFileManager defaultManager] copyItemAtPath:path toPath:destination_path error:&error];
  [meta_data writeToFile:[destination stringByAppendingPathComponent:@".meta"] atomically:NO];
}

@end
