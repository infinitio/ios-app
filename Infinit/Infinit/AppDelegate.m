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
#import "InfinitConstants.h"
#import "InfinitDeviceIdManager.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFacebookManager.h"
#import "InfinitFeedbackManager.h"
#import "InfinitGalleryManager.h"
#import "InfinitFilesOnboardingManager.h"
#import "InfinitLocalNotificationManager.h"
#import "InfinitMetricsManager.h"
#import "InfinitQuotaManager.h"
#import "InfinitRatingManager.h"
#import "InfinitWelcomeOnboardingController.h"
#import "InfinitWormhole.h"

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitGhostCodeManager.h>
#import <Gap/InfinitKeychain.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitURLParser.h>

#import "NSData+Conversion.h"

#import <Adjust/Adjust.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#ifdef DEBUG

# import <Gap/InfinitSwizzler.h>

@import AdSupport;

@implementation UIApplication (infinit_Debug)

+ (void)load
{
  static dispatch_once_t _uiapp_load_token = 0;
  dispatch_once(&_uiapp_load_token, ^
  {
    NSLog(@"Advertising identifier: %@",
          [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString);
    swizzle_class_selector(self.class, @selector(openURL:), @selector(infinit_openURL:));
  });
}

- (BOOL)infinit_openURL:(NSURL*)url
{
  NSLog(@"Opening URL: %@", url);
  return [self infinit_openURL:url];
}

@end

@implementation NSMutableArray (infinit_Debug)

+ (void)load
{
  static dispatch_once_t _mutablearray_load_token = 0;
  dispatch_once(&_mutablearray_load_token, ^
  {
    Class class = NSClassFromString(@"__NSArrayM");
    swizzle_class_selector(class, @selector(addObject:), @selector(infinit_addObject:));
    swizzle_class_selector(class,
                           @selector(insertObject:atIndex:),
                           @selector(infinit_insertObject:atIndex:));
    swizzle_class_selector(class,
                           @selector(removeObjectAtIndex:),
                           @selector(infinit_removeObjectAtIndex:));
  });
}

- (void)infinit_addObject:(id)anObject
{
  assert(anObject != nil);
  [self infinit_addObject:anObject];
}

- (void)infinit_insertObject:(id)anObject
                     atIndex:(NSUInteger)index
{
  assert(anObject != nil);
  [self infinit_insertObject:anObject atIndex:index];
}

- (void)infinit_removeObjectAtIndex:(NSUInteger)index
{
  assert(index < self.count);
  [self infinit_removeObjectAtIndex:index];
}

@end

#endif

@interface AppDelegate () <AdjustDelegate,
                           InfinitWelcomeOnboardingProtocol>

@property (nonatomic, readonly) BOOL onboarding;

@property (nonatomic, readonly) BOOL facebook_login;       // Doing some kind of Facebook login.
@property (nonatomic, readonly) BOOL facebook_quick_login; // Facebook login with valid token.
@property (nonatomic, readonly) BOOL facebook_long_login;  // Facebook login with expired token.

@property (nonatomic, readonly) NSString* logging_in_controller_id;
@property (nonatomic, readonly) NSString* main_controller_id;
@property (nonatomic, readonly) NSString* welcome_controller_id;
@property (nonatomic, readonly) NSString* welcome_onboarding_id;

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

- (void)configureAdjust
{
#if defined(DEBUG) || defined(ADJUST_TEST)
  NSString* environment = ADJEnvironmentSandbox;
  ADJLogLevel log_level = ADJLogLevelInfo;
#else
  NSString* environment = ADJEnvironmentProduction;
  ADJLogLevel log_level = ADJLogLevelWarn;
#endif
  ADJConfig* config = [ADJConfig configWithAppToken:kInfinitAdjustToken environment:environment];
  config.logLevel = log_level;
  config.delegate = self;
  [Adjust appDidLaunch:config];
}

- (BOOL)application:(UIApplication*)application
didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  [InfinitDeviceIdManager checkExistingOrStoreCurrentDeviceId];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    [UIView setAnimationsEnabled:NO];
  [self configureAdjust];
  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];
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
  [InfinitQuotaManager start];

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
    _onboarding = YES;
    [[InfinitApplicationSettings sharedInstance] setWelcome_onboarded:@1];
    UINavigationController* nav_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_onboarding_id];
    ((InfinitWelcomeOnboardingController*)nav_controller.topViewController).delegate = self;
    view_controller = nav_controller;
  }
  else
  {
    _onboarding = NO;
    if ([InfinitApplicationSettings sharedInstance].login_method == InfinitLoginFacebook)
    {
      if ([FBSDKAccessToken currentAccessToken])
      {
        _facebook_quick_login = YES;
        view_controller =
          [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
        [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:15.0f];
      }
      else
      {
        _facebook_long_login = YES;
        view_controller =
          [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
        [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:20.0f];
        FBSDKLoginManager* manager = [InfinitFacebookManager sharedInstance].login_manager;
        [manager logInWithReadPermissions:kInfinitFacebookReadPermissions
                                  handler:^(FBSDKLoginManagerLoginResult* result,
                                            NSError* error)
        {
          [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                   selector:@selector(tooLongToLogin)
                                                     object:nil];
          if (error)
          {
            UIAlertView* alert =
              [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Facebook login error", nil)
                                         message:error.localizedDescription
                                        delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"OK", nil) 
                               otherButtonTitles:nil];
            [alert show];
            self.root_controller =
              [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
            return;
          }
          if (result.isCancelled)
          {
            UIAlertView* alert =
              [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Facebook login canceled", nil)
                                         message:NSLocalizedString(@"", nil)
                                        delegate:nil 
                               cancelButtonTitle:NSLocalizedString(@"OK", nil) 
                               otherButtonTitles:nil];
            [alert show];
            self.root_controller =
              [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
            return;
          }
          [self tryFacebookLogin];
        }];
      }
    }
    else if ([self canAutoLogin])
    {
      if ([InfinitApplicationSettings sharedInstance].login_method == InfinitLoginNone)
        [InfinitApplicationSettings sharedInstance].login_method = InfinitLoginEmail;
      InfinitConnectionManager* manager = [InfinitConnectionManager sharedInstance];
      if (manager.network_status == InfinitNetworkStatusNotReachable)
      {
        view_controller =
          [self.storyboard instantiateViewControllerWithIdentifier:self.main_controller_id];
      }
      else
      {
        view_controller =
          [self.storyboard instantiateViewControllerWithIdentifier:self.logging_in_controller_id];
        [self performSelector:@selector(tooLongToLogin) withObject:nil afterDelay:15.0f];
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
  NSString* account = [InfinitApplicationSettings sharedInstance].username;
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
                              completionBlock:self.login_block];
}

- (void)tryFacebookLogin
{
  NSString* email = [InfinitApplicationSettings sharedInstance].username;
  NSString* token = [FBSDKAccessToken currentAccessToken].tokenString;
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:email 
                                        completionBlock:self.login_block];
}

- (InfinitStateCompletionBlock)login_block
{
  return ^void(InfinitStateResult* result)
  {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(tooLongToLogin)
                                               object:nil];
    UIViewController* view_controller = nil;
    if (result.success)
    {
      [InfinitBackgroundManager sharedInstance];
      [InfinitDeviceManager sharedInstance];
      [InfinitDownloadFolderManager sharedInstance];
      [InfinitGalleryManager sharedInstance];
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
  };
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
  [FBSDKAppEvents activateApp];

  [[UIApplication sharedApplication] cancelAllLocalNotifications];
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication*)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  [InfinitStateManager stopState];
}

#pragma mark - URL Handling

- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
  sourceApplication:(NSString*)sourceApplication
         annotation:(id)annotation
{
#ifdef DEBUG
  NSLog(@"Opened with URL: %@", url);
#endif
  [Adjust appWillOpenUrl:url];
  BOOL facebook_handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                         openURL:url
                                                               sourceApplication:sourceApplication
                                                                      annotation:annotation];
  NSString* ghost_code = [InfinitURLParser getGhostCodeFromURL:url];
  if (ghost_code.length)
    [[InfinitGhostCodeManager sharedInstance] setCode:ghost_code wasLink:YES completionBlock:nil];
  return (facebook_handled || ghost_code.length);
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
  if (deviceToken.infinit_hexadecimalString.length)
  {
    [InfinitStateManager sharedInstance].push_token = deviceToken.infinit_hexadecimalString;
    [self doneRegisterNotifications:YES];
  }
  else
  {
    [self doneRegisterNotifications:NO];
  }
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
  else if (self.facebook_login)
  {
    [self tryFacebookLogin];
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

#pragma mark - Login/Connection Notifications

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (connection_status.status)
  {
    if (![InfinitApplicationSettings sharedInstance].been_launched)
      [self handleFirstLaunch];
  }
  else if (!connection_status.status && !connection_status.still_trying)
  {
    self.root_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:self.welcome_controller_id];
  }
}

- (void)willLogout
{
  if ([InfinitApplicationSettings sharedInstance].login_method == InfinitLoginEmail)
  {
    NSString* account_email = [InfinitApplicationSettings sharedInstance].username;
    if (account_email != nil)
      [[InfinitKeychain sharedInstance] removeAccount:account_email];
  }
  [[InfinitWormhole sharedInstance] unregisterAllObservers];
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

- (NSString*)welcome_onboarding_id
{
  return @"welcome_onboarding_nav_controller_id";
}

#pragma mark - Adjust Delegate

- (void)adjustAttributionChanged:(ADJAttribution*)attribution
{
  if (attribution.clickLabel)
  {
    [InfinitMetricsManager sendMetric:InfinitUIEventAttribution
                               method:InfinitUIMethodSuccess 
                           additional:@{@"code": attribution.clickLabel}];
  }
  else
  {
    [InfinitMetricsManager sendMetric:InfinitUIEventAttribution method:InfinitUIMethodFail];
  }
}

#pragma mark - Shake Handling

- (void)handleShakeEvent:(UIEvent*)event
{
  [[InfinitFeedbackManager sharedInstance] gotShake:event];
}

@end
