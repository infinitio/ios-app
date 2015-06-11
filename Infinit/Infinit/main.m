//
//  main.m
//  Infinit
//
//  Created by Christopher Crone on 12/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "InfinitApplication.h"

int main(int argc, char* argv[])
{
  @autoreleasepool
  {
    NSString* app_name = NSStringFromClass(InfinitApplication.class);
    NSString* delegate_name = NSStringFromClass(AppDelegate.class);
    return UIApplicationMain(argc, argv, app_name, delegate_name);
  }
}
