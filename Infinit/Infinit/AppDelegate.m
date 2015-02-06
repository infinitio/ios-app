//
//  AppDelegate.m
//  Infinit
//
//  Created by Christopher Crone on 08/10/14.
//  Copyright (c) 2014 Christopher Crone. All rights reserved.
//

#import "AppDelegate.h"

#import "InfinitApplicationSettings.h"
#import "InfinitBackgroundManager.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitKeychain.h"
#import "InfinitLocalNotificationManager.h"
#import "InfinitRatingManager.h"
#import "InfinitWelcomeOnboardingNavigationController.h"

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>

#import "NSData+Conversion.h"

@interface AppDelegate () <InfinitWelcomeOnboardingProtocol>

@property (nonatomic, weak) InfinitWelcomeOnboardingNavigationController* onboarding_controller;
@property (nonatomic, readonly) BOOL onboarding;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication*)application
didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  [InfinitConnectionManager sharedInstance];
  [InfinitStateManager startState];

  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

  if (![[[InfinitApplicationSettings sharedInstance] welcome_onboarded] isEqualToNumber:@1])
  {
    _onboarding = YES;
    [[InfinitApplicationSettings sharedInstance] setWelcome_onboarded:@1];
    self.onboarding_controller =
      [storyboard instantiateViewControllerWithIdentifier:@"welcome_onboarding"];
    self.onboarding_controller.delegate = self;
    self.window.rootViewController = self.onboarding_controller;
  }
  else
  {
    _onboarding = NO;
    if ([self canAutoLogin])
    {
      self.window.rootViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"logging_in_controller"];
    }
    else
    {
      self.window.rootViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"welcome_controller"];
    }
  }
  [self.window makeKeyAndVisible];

  [self registerForNotifications];

  return YES;
}

- (BOOL)canAutoLogin
{
  NSString* account = [[InfinitApplicationSettings sharedInstance] username];
  if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:account])
    return YES;
  return NO;
}

- (void)tryLogin
{
  NSString* username = [[InfinitApplicationSettings sharedInstance] username];
  NSString* password = [[InfinitKeychain sharedInstance] passwordForAccount:username];
  if (password == nil)
    password = @"";
  [[InfinitStateManager sharedInstance] login:username
                                     password:password
                              performSelector:@selector(loginCallback:)
                                     onObject:self];
  password = nil;
}

- (void)loginCallback:(InfinitStateResult*)result
{
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  NSString* identifier = nil;
  if (result.success)
  {
    [InfinitDownloadFolderManager sharedInstance];
    [InfinitBackgroundManager sharedInstance];
    [InfinitRatingManager sharedInstance];
    identifier = @"tab_bar_controller";
  }
  else
  {
    identifier = @"welcome_controller";
  }
  self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
  [self.window makeKeyAndVisible];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
  [[InfinitAvatarManager sharedInstance] clearCachedAvatars];
}

//Facebook SDK url handling
//- (BOOL)application:(UIApplication*)application
//            openURL:(NSURL*)url
//  sourceApplication:(NSString*)sourceApplication
//         annotation:(id)annotation {
//  // attempt to extract a token from the url
//  return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
//}

- (void)applicationWillResignActive:(UIApplication*)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication*)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  [InfinitStateManager stopState];
}

// This method will handle ALL the session state changes in the app
//- (void)sessionStateChanged:(FBSession*)session
//                      state:(FBSessionState)state
//                      error:(NSError*)error
//{
//  
//  // If the session was opened successfully
//  if (!error && state == FBSessionStateOpen)
//  {
//    NSLog(@"Session opened");
//    // Take the information and add it to InfinitUserObject.
//    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection* connection, NSDictionary<FBGraphUser>* FBuser, NSError* error)
//    {
//      if (error)
//      {
//        // Handle error
//      }
//      else
//      {
//        
//        NSString* userName =
//          [FBuser name];
//        NSString* userImageURL =
//          [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [FBuser objectID]];
//      }
//    }];
//    return;
//  }
//  if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
//    // If the session is closed
//    NSLog(@"Session closed");
//    
//  }
//}

#pragma mark - Notification Handling

- (void)registerForNotifications
{
  if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
  {
    UIUserNotificationType types =
      UIUserNotificationTypeBadge |
      UIUserNotificationTypeSound |
      UIUserNotificationTypeAlert;
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types
                                                                             categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }
  else
  {
    UIRemoteNotificationType types =
      UIRemoteNotificationTypeAlert |
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound;
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
  }
}

- (void)application:(UIApplication*)applocatopm
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
  [InfinitStateManager sharedInstance].push_token = deviceToken.hexadecimalString;
  if ([self canAutoLogin] && !self.onboarding)
    [self tryLogin];
}

- (void)application:(UIApplication*)application
didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
  if ([self canAutoLogin] && !self.onboarding)
    [self tryLogin];
}

- (void)application:(UIApplication*)application
handleActionWithIdentifier:(NSString*)identifier
forRemoteNotification:(NSDictionary*)userInfo
  completionHandler:(void(^)())completionHandler
{
  completionHandler();
}

- (void)application:(UIApplication*)application
handleActionWithIdentifier:(NSString*)identifier
forLocalNotification:(UILocalNotification*)notification
  completionHandler:(void(^)())completionHandler
{
  completionHandler();
}

- (void)application:(UIApplication*)application
didReceiveRemoteNotification:(NSDictionary*)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
  {
    completionHandler(UIBackgroundFetchResultNoData);
    return;
  }

  [self performSelector:@selector(delayedCompletionHandlerWithNewData:)
             withObject:completionHandler
             afterDelay:10.0f];

//  NSDictionary* dict = userInfo[@"i"];
//  UIBackgroundFetchResult res =
//    [[InfinitLocalNotificationManager sharedInstance] localNotificationForRemoteNotification:dict];
//  if (res == UIBackgroundFetchResultNewData)
//  {
//    [self performSelector:@selector(delayedCompletionHandlerWithNewData:)
//               withObject:completionHandler
//               afterDelay:10.0f];
//  }
//  else
//  {
//      completionHandler(res);
//  }
}

- (void)delayedCompletionHandlerWithNewData:(void (^)(UIBackgroundFetchResult))completionHandler
{
  completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark - Welcome Onboarding Protocol

- (void)welcomeOnboardingDone
{
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  if ([self canAutoLogin])
  {
    [self tryLogin];
    self.window.rootViewController =
      [storyboard instantiateViewControllerWithIdentifier:@"logging_in_controller"];
  }
  else
  {
    self.window.rootViewController =
      [storyboard instantiateViewControllerWithIdentifier:@"welcome_controller"];
  }
  [self.window makeKeyAndVisible];
  self.onboarding_controller = nil;
}


@end
