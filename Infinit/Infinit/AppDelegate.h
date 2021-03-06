//
//  AppDelegate.h
//  Infinit
//
//  Created by Christopher Crone on 12/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readwrite) UIViewController* root_controller;
@property (nonatomic, strong) UIWindow* window;

- (void)handleShakeEvent:(UIEvent*)event;

@end

