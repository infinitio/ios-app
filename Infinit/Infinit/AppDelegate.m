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
#import "InfinitFacebookManager.h"
#import "InfinitFilesOnboardingManager.h"
#import "InfinitKeychain.h"
#import "InfinitLocalNotificationManager.h"
#import "InfinitMetricsManager.h"
#import "InfinitRatingManager.h"
#import "InfinitWelcomeOnboardingNavigationController.h"

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

#import "NSData+Conversion.h"

#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate () <InfinitWelcomeOnboardingProtocol>

@property (nonatomic, weak) InfinitWelcomeOnboardingNavigationController* onboarding_controller;
@property (nonatomic, readonly) BOOL onboarding;

@end

@implementation AppDelegate

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)application:(UIApplication*)application
didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  [InfinitConnectionManager sharedInstance];
  [InfinitStateManager startState];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(willLogout)
                                               name:INFINIT_WILL_LOGOUT_NOTIFICATION
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(connectionStatusChanged:)
                                               name:INFINIT_CONNECTION_STATUS_CHANGE
                                             object:nil];

  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

  if (![[[InfinitApplicationSettings sharedInstance] welcome_onboarded] isEqualToNumber:@1])
  {
    [FBSession activeSession]; // Ensure that we call FBSession on the main thread at least once.
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
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded)
    {
      self.window.rootViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"logging_in_controller"];
      [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:25.0f];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(facebookSessionStateChanged:)
                                                   name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                                 object:nil];
      InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
      // If there's one, just open the session silently, without showing the user the login UI
      [FBSession openActiveSessionWithReadPermissions:manager.permission_list
                                         allowLoginUI:NO
                                    completionHandler:^(FBSession* session,
                                                        FBSessionState state,
                                                        NSError* error)
       {
         // Handler for session state changes
         // Call this method EACH time the session state changes,
         // NOT just when the session open
         [manager sessionStateChanged:session state:state error:error];
       }];
    }
    else if (FBSession.activeSession.state == FBSessionStateCreatedOpening||
             FBSession.activeSession.state == FBSessionStateOpen ||
             FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
    {
      self.window.rootViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"logging_in_controller"];
      [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:15.0f];
      [self tryFacebookLogin];
    }
    else if ([self canAutoLogin])
    {
      InfinitConnectionManager* manager = [InfinitConnectionManager sharedInstance];
      if (manager.network_status != InfinitNetworkStatusNotReachable)
      {
        self.window.rootViewController =
          [storyboard instantiateViewControllerWithIdentifier:@"logging_in_controller"];
        [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:15.0f];
      }
      else
      {
        self.window.rootViewController =
          [storyboard instantiateViewControllerWithIdentifier:@"tab_bar_controller"];
      }
    }
    else
    {
      self.window.rootViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"welcome_controller"];
    }
  }
  [self.window makeKeyAndVisible];

  [self registerForNotifications];

  [InfinitMetricsManager sendMetric:InfinitUIEventAppOpen method:InfinitUIMethodNew];

  return YES;
}

- (BOOL)canAutoLogin
{
  NSString* account = [[InfinitApplicationSettings sharedInstance] username];
  if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:account])
    return YES;
  return NO;
}

- (void)tooLongToLogin
{
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  self.window.rootViewController =
    [storyboard instantiateViewControllerWithIdentifier:@"tab_bar_controller"];
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
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(tooLongToLogin)
                                             object:nil];
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  NSString* identifier = nil;
  if (result.success)
  {
    [InfinitDeviceManager sharedInstance];
    [InfinitUserManager sharedInstance];
    [InfinitPeerTransactionManager sharedInstance];
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
  [InfinitMetricsManager sendMetric:InfinitUIEventAppOpen method:InfinitUIMethodRepeat];
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

  // Handle the user leaving the app while the Facebook login dialog is being shown
  // For example: when the user presses the iOS "home" button while the login dialog is active
  [FBAppCall handleDidBecomeActive];

  [[UIApplication sharedApplication] cancelAllLocalNotifications];
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication*)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  [[InfinitFacebookManager sharedInstance] closeSession];
  [InfinitStateManager stopState];
}

#pragma mark - URL Handling

- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
  sourceApplication:(NSString*)sourceApplication
         annotation:(id)annotation
{
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  // Note this handler block should be the exact same as the handler passed to any open calls.
  [FBSession.activeSession setStateChangeHandler:^(FBSession* session,
                                                   FBSessionState state,
                                                   NSError* error)
   {
     // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
     [manager sessionStateChanged:session state:state error:error];
   }];

  // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
  BOOL was_handled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];

  // You can add your app-specific url handling code here if needed

  return was_handled;
}

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

- (void)application:(UIApplication*)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
  [InfinitStateManager sharedInstance].push_token = deviceToken.hexadecimalString;
  if ([self canAutoLogin] && !self.onboarding)
    [self tryLogin];
  if (![InfinitApplicationSettings sharedInstance].asked_notifications)
  {
    [InfinitApplicationSettings sharedInstance].asked_notifications = YES;
    [InfinitMetricsManager sendMetric:InfinitUIEventAccessNotifications method:InfinitUIMethodYes];
  }
}

- (void)application:(UIApplication*)application
didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
  if ([self canAutoLogin] && !self.onboarding)
    [self tryLogin];
  if (![InfinitApplicationSettings sharedInstance].asked_notifications)
  {
    [InfinitApplicationSettings sharedInstance].asked_notifications = YES;
    [InfinitMetricsManager sendMetric:InfinitUIEventAccessNotifications method:InfinitUIMethodNo];
  }
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

#pragma mark - Facebok Session State Changed

- (void)tryFacebookLogin
{
  NSString* email = [InfinitApplicationSettings sharedInstance].username;
  NSString* token = FBSession.activeSession.accessTokenData.accessToken;
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:email
                                        performSelector:@selector(loginCallback:)
                                               onObject:self];
}

- (void)facebookSessionStateChanged:(NSNotification*)notification
{
  FBSessionState state = [notification.userInfo[@"state"] unsignedIntegerValue];
  if (state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended)
  {
    [self tryFacebookLogin];
  }
  else
  {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(tooLongToLogin)
                                               object:nil];
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NSString* identifier = identifier = @"welcome_controller";
    self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    [self.window makeKeyAndVisible];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                                object:nil];
}

#pragma mark - Login/Connection Notifications

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (connection_status.status)
  {
    if (![InfinitApplicationSettings sharedInstance].been_launched)
      [self handleFirstLaunch];
  }
}

- (void)willLogout
{
  if (FBSession.activeSession.state == FBSessionStateOpen
      || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
  {
    [[InfinitFacebookManager sharedInstance] cleanSession];
  }
}

#pragma mark - First Launch

- (void)handleFirstLaunch
{
  [[InfinitPeerTransactionManager sharedInstance] archiveIrrelevantTransactions];
  [InfinitApplicationSettings sharedInstance].been_launched = YES;
  [InfinitFilesOnboardingManager copyFilesForOnboarding];
}

@end
