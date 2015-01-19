//
//  AppDelegate.m
//  Infinit
//
//  Created by Christopher Crone on 08/10/14.
//  Copyright (c) 2014 Christopher Crone. All rights reserved.
//

#import "AppDelegate.h"

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>

#import "InfinitApplicationSettings.h"
#import "InfinitKeychain.h"

@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication*)application
didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  [InfinitConnectionManager sharedInstance];
  [InfinitStateManager startState];

  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  NSString* identifier = nil;

  NSString* account = [[InfinitApplicationSettings sharedInstance] username];
  if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:account])
  {
    [self tryLogin];
    identifier = @"logging_in_controller";
  }
  else
  {
    identifier = @"welcome_controller";
  }
  self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
  [self.window makeKeyAndVisible];
  return YES;
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


@end
