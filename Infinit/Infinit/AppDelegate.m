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

#import "NSData+Conversion.h"

#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate () <InfinitWelcomeOnboardingProtocol>

@property (nonatomic, weak) InfinitWelcomeOnboardingNavigationController* onboarding_controller;
@property (nonatomic, readonly) BOOL onboarding;

@property (nonatomic, readonly) BOOL facebook_login;       // Doing some kind of Facebook login.
@property (nonatomic, readonly) BOOL facebook_quick_login; // Facebook login with valid token.
@property (nonatomic, readonly) BOOL facebook_long_login;  // Facebook login with expired token.

@property (nonatomic, readonly) NSString* logging_in_controller_id;
@property (nonatomic, readonly) NSString* main_controller_id;
@property (nonatomic, readonly) NSString* welcome_controller_id;

@property (nonatomic, readwrite) UIViewController* root_controller;

@end

@implementation AppDelegate

- (BOOL)facebook_login
{
  return (self.facebook_quick_login || self.facebook_long_login);
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)application:(UIApplication*)application
didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  [[InfinitKeychain sharedInstance] removeAccount:@"chris@infinit.io"];
  UIViewController* view_controller = nil;
  if (![InfinitApplicationSettings sharedInstance].been_launched)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(archiveOldTransactions)
                                                 name:INFINIT_PEER_TRANSACTION_MODEL_READY_NOTIFICATION
                                               object:nil];
  }
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

  if (![[[InfinitApplicationSettings sharedInstance] welcome_onboarded] isEqualToNumber:@1])
  {
    [FBSession activeSession]; // Ensure that we call FBSession on the main thread at least once.
    _onboarding = YES;
    [[InfinitApplicationSettings sharedInstance] setWelcome_onboarded:@1];
    self.onboarding_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"welcome_onboarding"];
    self.onboarding_controller.delegate = self;
    view_controller = self.onboarding_controller;
  }
  else
  {
    _onboarding = NO;
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded)
    {
      _facebook_long_login = YES;
      view_controller =
        [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
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
      _facebook_quick_login = YES;
      view_controller =
        [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
      [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:15.0f];
    }
    else if ([self canAutoLogin])
    {
      InfinitConnectionManager* manager = [InfinitConnectionManager sharedInstance];
      if (manager.network_status != InfinitNetworkStatusNotReachable)
      {
        view_controller =
          [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
        [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:15.0f];
      }
      else
      {
        view_controller =
          [self.storyboard instantiateViewControllerWithIdentifier:self.main_controller_id];
      }
    }
    else
    {
      view_controller =
        [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
    }
  }
  if (view_controller)
  {
    dispatch_async(dispatch_get_main_queue(), ^
    {
      self.root_controller = view_controller;
    });
  }
  [self registerForNotifications];

  [InfinitMetricsManager sendMetric:InfinitUIEventAppOpen method:InfinitUIMethodNew];

  return YES;
}

- (BOOL)canAutoLogin
{
  NSString* account = [[InfinitApplicationSettings sharedInstance] username];
  if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:account])
    return YES;
  // Ensure that credentials are removed. Fixes issue with beta users not able to auto login.
  [[InfinitKeychain sharedInstance] removeAccount:account];
  return NO;
}

- (void)tooLongToLogin
{
  self.root_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:self.main_controller_id];
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
  UIViewController* view_controller = nil;
  if (result.success)
  {
    [InfinitDeviceManager sharedInstance];
    [InfinitDownloadFolderManager sharedInstance];
    [InfinitBackgroundManager sharedInstance];
    [InfinitRatingManager sharedInstance];
    view_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.main_controller_id];
  }
  else
  {
    view_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
  }
  dispatch_async(dispatch_get_main_queue(), ^
  {
    self.root_controller = view_controller;
  });
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

- (void)doneRegisterNotifications:(BOOL)allowed
{
  if ([self canAutoLogin] && !self.onboarding && !self.facebook_login)
    [self tryLogin];
  else if (self.facebook_quick_login)
    [self tryFacebookLogin];
  if (![InfinitApplicationSettings sharedInstance].asked_notifications)
  {
    [InfinitApplicationSettings sharedInstance].asked_notifications = YES;
    InfinitUIMethods method = allowed ? InfinitUIMethodYes : InfinitUIMethodNo;
    [InfinitMetricsManager sendMetric:InfinitUIEventAccessNotifications method:method];
  }
}

- (void)application:(UIApplication*)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
  [InfinitStateManager sharedInstance].push_token = deviceToken.hexadecimalString;
  if (deviceToken.hexadecimalString.length)
    [self doneRegisterNotifications:YES];
  else
    [self doneRegisterNotifications:NO];
}

- (void)application:(UIApplication*)application
didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
  [self doneRegisterNotifications:NO];
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
  UIViewController* view_controller = nil;
  if ([self canAutoLogin])
  {
    [self tryLogin];
     view_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
  }
  else
  {
    view_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
  }
  self.root_controller = view_controller;
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
    self.root_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
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
  if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded ||
      FBSession.activeSession.state == FBSessionStateCreatedOpening||
      FBSession.activeSession.state == FBSessionStateOpen ||
      FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
  {
    [[InfinitFacebookManager sharedInstance] cleanSession];
  }
  else
  {
    NSString* account_email = [InfinitApplicationSettings sharedInstance].username;
    if (account_email != nil)
      [[InfinitKeychain sharedInstance] removeAccount:account_email];
  }
}

#pragma mark - First Launch

- (void)handleFirstLaunch
{
  [InfinitApplicationSettings sharedInstance].been_launched = YES;
  [InfinitFilesOnboardingManager copyFilesForOnboarding];
}

- (void)archiveOldTransactions
{
  [[InfinitPeerTransactionManager sharedInstance] archiveIrrelevantTransactions];
}

#pragma mark - Helpers

- (void)setRoot_controller:(UIViewController*)root_controller
{
  self.window.rootViewController = root_controller;
}

- (UIViewController*)root_controller
{
  return self.window.rootViewController;
}

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

- (NSString*)logging_in_controller_id
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return @"logging_in_controller";
  else
    return @"logging_in_controller_portrait";
}

- (NSString*)main_controller_id
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return @"main_controller_ipad";
  else
    return @"main_controller_id";
}

- (NSString*)welcome_controller_id
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return @"welcome_controller_id";
  else
    return @"welcome_nav_controller_id";
}

@end
