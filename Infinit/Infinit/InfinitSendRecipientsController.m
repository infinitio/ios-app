//
//  InfinitSendRecipientsController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendRecipientsController.h"

#import "InfinitAccessContactsView.h"
#import "InfinitApplicationSettings.h"
#import "InfinitConstants.h"
#import "InfinitContact.h"
#import "InfinitContactImportCell.h"
#import "InfinitContactManager.h"
#import "InfinitFacebookManager.h"
#import "InfinitSendGalleryController.h"
#import "InfinitHostDevice.h"
#import "InfinitImportOverlayView.h"
#import "InfinitInvitationOverlayViewController.h"
#import "InfinitMessagingManager.h"
#import "InfinitMetricsManager.h"
#import "InfinitOverlayViewController.h"
#import "InfinitQuotaManager.h"
#import "InfinitSendContactCell.h"
#import "InfinitSendDeviceCell.h"
#import "InfinitSendEmailCell.h"
#import "InfinitSendNavigationController.h"
#import "InfinitSendNoResultsCell.h"
#import "InfinitSendToSelfOverlayView.h"
#import "InfinitSendUserCell.h"
#import "InfinitStatusBarNotifier.h"
#import "InfinitTabBarController.h"
#import "InfinitUploadThumbnailManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitColor.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitExternalAccountsManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/NSString+email.h>
#import <Gap/NSString+PhoneNumber.h>

#import "VENTokenField.h"

@import AddressBook;
@import AssetsLibrary;
@import Photos;

typedef NS_ENUM(NSUInteger, InfinitSendRecipientsSection)
{
  InfinitSendRecipientsSectionSelf      = 0,
  InfinitSendRecipientsSectionSwaggers  = 1,
  InfinitSendRecipientsSectionContacts  = 2,

  InfinitSendRecipientsSectionCount,
};

@interface InfinitSendRecipientsController () <InfinitInvitationOverlayProtocol,
                                               UIActionSheetDelegate,
                                               UITextFieldDelegate,
                                               UIGestureRecognizerDelegate,
                                               VENTokenFieldDelegate,
                                               VENTokenFieldDataSource>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* add_contacts_button;
@property (nonatomic, weak) IBOutlet VENTokenField* search_field;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UIButton* send_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_constraint;

@property (nonatomic, strong) InfinitAccessContactsView* contacts_overlay;
@property (nonatomic, strong) InfinitImportOverlayView* import_overlay;
@property (nonatomic, strong) InfinitSendToSelfOverlayView* send_to_self_overlay;

@property (nonatomic) BOOL no_devices;
@property (nonatomic) BOOL email_entered;
@property (nonatomic, strong) InfinitContactUser* me_contact;
@property (atomic, strong) NSMutableArray* all_devices;
@property (atomic, strong) NSMutableArray* device_results;
@property (atomic, strong) NSMutableArray* all_swaggers;
@property (atomic, strong) NSMutableArray* swagger_results;
@property (atomic, strong) NSMutableArray* all_contacts;
@property (atomic, strong) NSMutableArray* contact_results;
@property (atomic, strong) NSMutableOrderedSet* recipients;

@property (nonatomic, readonly) BOOL can_send_sms;
@property (atomic) BOOL preloading_contacts;
@property (atomic, readwrite) NSString* last_search;
@property (nonatomic, readonly) UITapGestureRecognizer* nav_bar_tap;
@property (nonatomic, readonly) NSArray* thumbnail_elements;

@property (atomic, readwrite) BOOL sent_to_contact;
@property (atomic, readwrite) InfinitMessagingRecipient* current_message_recipient;
@property (nonatomic, readonly) InfinitInvitationOverlayViewController* invitation_overlay;
@property (nonatomic, readonly) dispatch_once_t invitation_overlay_token;

@end

static NSString* _device_cell_id = @"send_device_cell";
static NSString* _email_cell_id = @"send_email_cell";
static NSString* _infinit_user_cell_id = @"send_user_infinit_cell";
static NSString* _contact_cell_id = @"send_contact_cell";
static NSString* _import_cell_id = @"contact_import_cell";
static NSString* _no_results_cell_id = @"send_no_results_cell";

static NSUInteger _max_recipients = 10;

static UIImage* _send_button_image = nil;

@implementation InfinitSendRecipientsController

@synthesize file_count = _file_count;
@synthesize invitation_overlay = _invitation_overlay;
@synthesize managed_files = _managed_files;

#pragma mark - Init

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)viewDidLoad
{
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  self.send_button.titleEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     - self.send_button.imageView.frame.size.width,
                     0.0f,
                     self.send_button.imageView.frame.size.width);
  self.send_button.imageEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     self.send_button.titleLabel.frame.size.width + 10.0f,
                     0.0f,
                     - (self.send_button.titleLabel.frame.size.width + 10.0f));
  self.search_field.inputTextFieldKeyboardType = UIKeyboardTypeEmailAddress;
  self.search_field.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.search_field.autocorrectionType = UITextAutocorrectionTypeNo;

  [super viewDidLoad];

  UINib* import_cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitContactImportCell.class)
                                          bundle:nil];
  [self.table_view registerNib:import_cell_nib forCellReuseIdentifier:_import_cell_id];

  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.table_view.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.table_view.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    self.navigationItem.title = NSLocalizedString(@"SELECT CONTACT", nil);
    [self.navigationItem.leftBarButtonItem setImage:[UIImage imageNamed:@"icon-close"]];
  }
  else
  {
    self.navigationItem.title = NSLocalizedString(@"SEND", nil);
  }
  if (!_send_button_image)
    _send_button_image = [UIImage imageNamed:@"icon-send-white"];
}

- (void)configureSearchField
{
  if (self.swagger_results.count > 1)
  {
    self.search_field.placeholderText =
      NSLocalizedString(@"Search contacts by name or email...", nil);
  }
  else
  {
    self.search_field.placeholderText =
      NSLocalizedString(@"Type email or send to yourself...", nil);
  }
  self.search_field.toLabelTextColor = [UIColor blackColor];
  self.search_field.maxHeight = 112.0f;
  self.search_field.delegate = self;
  self.search_field.dataSource = self;
  [self.search_field reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self fetchDevices];
  [self fetchSwaggers];
  [self configureSearchField];
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userAvatarFetched:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newUserAdded:)
                                               name:INFINIT_NEW_USER_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newUserAdded:)
                                               name:INFINIT_CONTACT_JOINED_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(managedFilesDeleted:)
                                               name:INFINIT_MANAGED_FILES_DELETED
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleGhostTransaction:)
                                               name:INFINIT_PEER_GHOST_TRANSACTION_NOTIFICATION
                                             object:nil];

  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    self.preloading_contacts = YES;
    [self fetchAddressBook];
  }
  else
  {
    self.preloading_contacts = NO;
  }
  [self setAddContactsButtonHidden:[InfinitExternalAccountsManager sharedInstance].have_facebook];
}

- (void)setAddContactsButtonHidden:(BOOL)hidden
{
  NSArray* toolbar_items = self.navigationItem.rightBarButtonItems;
  if (hidden && [toolbar_items containsObject:self.add_contacts_button])
  {
    NSMutableArray* res = [toolbar_items mutableCopy];
    [res removeObject:self.add_contacts_button];
    self.navigationItem.rightBarButtonItems = res;
  }
  else if (!hidden &&
           self.add_contacts_button &&![toolbar_items containsObject:self.add_contacts_button])
  {
    NSMutableArray* res = [toolbar_items mutableCopy];
    [res addObject:self.add_contacts_button];
    self.navigationItem.rightBarButtonItems = res;
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  _nav_bar_tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(navBarTapped)];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:self.nav_bar_tap];
  if (self.recipient != nil)
  {
    NSUInteger section = NSNotFound;
    NSUInteger row = NSNotFound;
    if ([self.recipient isKindOfClass:InfinitContactUser.class])
    {
      InfinitContactUser* contact = (InfinitContactUser*)self.recipient;
      if (contact.infinit_user.is_self)
      {
        section = InfinitSendRecipientsSectionSelf;
        row = 0;
      }
      else
      {
        section = InfinitSendRecipientsSectionSwaggers;
        row = [self.swagger_results indexOfObject:self.recipient];
      }
    }
    if (section != NSNotFound && row != NSNotFound)
      [self selectIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
  }
  NSString* title = nil;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    if (self.file_count == 0)
    {
      title = NSLocalizedString(@"SEND", nil);
    }
    else if (self.file_count == 1)
    {
      title = NSLocalizedString(@"SEND 1 FILE", nil);
    }
    else
    {
      title = [NSString stringWithFormat:NSLocalizedString(@"SEND %lu FILES", nil),
               self.file_count];
    }
    self.navigationItem.title = title;
  }
}

- (void)navBarTapped
{
  [self.table_view scrollRectToVisible:CGRectMake(0.0f, 1.0f, 1.0f, 1.0f) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  self.recipient = nil;
  [self.navigationController.navigationBar.subviews[0] removeGestureRecognizer:self.nav_bar_tap];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
  _nav_bar_tap = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

#pragma mark - General

- (NSUInteger)file_count
{
  @synchronized(self)
  {
    return _file_count;
  }
}

- (void)setFile_count:(NSUInteger)file_count
{
  @synchronized(self)
  {
    _file_count = file_count;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      [self updateSendButton];
  }
}

- (InfinitManagedFiles*)managed_files
{
  return _managed_files;
}

- (void)setManaged_files:(InfinitManagedFiles*)managed_files
{
  _managed_files = managed_files;
  if (!managed_files)
    _file_count = 0;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    [self updateSendButton];
}

- (void)resetView
{
  [self.recipients removeAllObjects];
  if (self.managed_files)
    [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:self.managed_files];
  self.managed_files = nil;
}

- (void)fetchDevices
{
  InfinitUser* me = [InfinitUserManager sharedInstance].me;
  [[InfinitDeviceManager sharedInstance] updateDevices];
  NSArray* other_devices = [InfinitDeviceManager sharedInstance].other_devices;
  if (self.all_devices == nil)
    _all_devices = [NSMutableArray array];
  else
    [self.all_devices removeAllObjects];
  if (other_devices.count == 0)
  {
    _no_devices = YES;
    [self.all_devices addObject:[InfinitContactUser contactWithInfinitUser:me]];
  }
  else
  {
    _no_devices = NO;
    for (InfinitDevice* device in other_devices)
    {
      InfinitContactUser* contact = [InfinitContactUser contactWithInfinitUser:me andDevice:device];
      [self.all_devices addObject:contact];
    }
  }
  self.device_results = [self.all_devices mutableCopy];
}

- (NSMutableArray*)swaggers
{
  NSMutableArray* res = [NSMutableArray array];
  InfinitUserManager* manager = [InfinitUserManager sharedInstance];
  for (InfinitUser* user in [manager favorites])
  {
    if (!user.deleted)
      [res addObject:[InfinitContactUser contactWithInfinitUser:user]];
  }
  for (InfinitUser* user in [manager time_ordered_swaggers])
  {
    if (!user.deleted)
      [res addObject:[InfinitContactUser contactWithInfinitUser:user]];
  }
  return res;
}

- (void)fetchSwaggers
{
  self.all_swaggers = [self swaggers];
  self.swagger_results = [self.all_swaggers mutableCopy];
  [self.table_view reloadData];
}

- (void)fetchAddressBook
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
      self.all_contacts = [[[InfinitContactManager sharedInstance] allContacts] mutableCopy];
      self.contact_results = [self.all_contacts mutableCopy];
      dispatch_sync(dispatch_get_main_queue(), ^
      {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:InfinitSendRecipientsSectionContacts];
        [self reloadTableSections:indexes];
        if (self.recipient)
        {
          NSUInteger row = [self.contact_results indexOfObject:self.recipient];
          if (row != NSNotFound)
          {
            NSIndexPath* index = [NSIndexPath indexPathForRow:row
                                                    inSection:InfinitSendRecipientsSectionContacts];
            [self selectIndexPath:index];
          }
        }
      });
    }
    self.preloading_contacts = NO;
  });
}

- (void)reloadTableSections:(NSIndexSet*)set
{
  NSRange section_range = NSMakeRange(0, self.table_view.numberOfSections);
  if ([set containsIndexes:[NSIndexSet indexSetWithIndexesInRange:section_range]])
    [self.table_view reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
  else
    [self.table_view reloadData];
}

- (void)selectIndexPath:(NSIndexPath*)index
{
  [self.table_view selectRowAtIndexPath:index
                               animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
  [self tableView:self.table_view didSelectRowAtIndexPath:index];
}

#pragma mark - Overlays

- (void)showImportOverlay
{
  if (self.import_overlay == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:@"InfinitImportOverlayView" bundle:nil];
    self.import_overlay = [[overlay_nib instantiateWithOwner:self options:nil] firstObject];
    [self.import_overlay.facebook_button addTarget:self
                                            action:@selector(addFacebookContacts:)
                                  forControlEvents:UIControlEventTouchUpInside];
    [self.import_overlay.back_button addTarget:self
                                        action:@selector(cancelOverlayFromButton:)
                              forControlEvents:UIControlEventTouchUpInside];
  }
  [self showOverlayView:self.import_overlay];
}

- (void)showAddressBookOverlay
{
  UINib* overlay_nib = [UINib nibWithNibName:NSStringFromClass(InfinitAccessContactsView.class)
                                      bundle:nil];
  self.contacts_overlay = [[overlay_nib instantiateWithOwner:self options:nil] firstObject];
  [self.contacts_overlay.access_button addTarget:self
                                          action:@selector(accessAddressBook:)
                                forControlEvents:UIControlEventTouchUpInside];
  [self.contacts_overlay.back_button addTarget:self
                                        action:@selector(cancelOverlayFromButton:)
                              forControlEvents:UIControlEventTouchUpInside];
  self.contacts_overlay.contacts_image.hidden = NO;
  [self showOverlayView:self.contacts_overlay];
}

- (void)showSendToSelfOverlay
{
  if (self.send_to_self_overlay == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSendToSelfOverlayView.class)
                                        bundle:nil];
    self.send_to_self_overlay = [[overlay_nib instantiateWithOwner:self options:nil] firstObject];
    [self.send_to_self_overlay.send_email_button addTarget:self
                                                    action:@selector(cancelOverlayFromButton:)
                                          forControlEvents:UIControlEventTouchUpInside];
  }
  [self showOverlayView:self.send_to_self_overlay];
}

- (void)showOverlayView:(UIView*)view
{
  self.view.userInteractionEnabled = NO;
  view.alpha = 0.0f;
  view.frame = [[UIScreen mainScreen] applicationFrame];
  [[UIApplication sharedApplication].keyWindow addSubview:view];
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 1.0f;
   } completion:^(BOOL finished)
   {
     if (!finished)
       view.alpha = 1.0f;
   }];
}

- (void)accessAddressBook:(id)sender
{
  NSDictionary* bold_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold"
                                                                    size:20.0f],
                               NSForegroundColorAttributeName: [UIColor whiteColor]};
  self.contacts_overlay.message_label.text =
    NSLocalizedString(@"Tap 'OK' so we can display your contacts.", nil);
  NSMutableAttributedString* res = [self.contacts_overlay.message_label.attributedText mutableCopy];
  NSRange bold_range = [res.string rangeOfString:@"OK"];
  [res setAttributes:bold_attrs range:bold_range];
  self.contacts_overlay.message_label.attributedText = res;
  self.contacts_overlay.access_button.hidden = YES;
  self.contacts_overlay.back_button.hidden = YES;
  self.contacts_overlay.contacts_image.hidden = YES;
  ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, NULL);
  ABAddressBookRequestAccessWithCompletion(address_book, ^(bool granted, CFErrorRef error)
  {
    if (granted)
    {
      self.preloading_contacts = YES;
      [self fetchAddressBook];
      [InfinitMetricsManager sendMetric:InfinitUIEventAccessContacts method:InfinitUIMethodYes];
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventAccessContacts method:InfinitUIMethodNo];
    }
    dispatch_async(dispatch_get_main_queue(), ^
    {
      [self cancelOverlay:sender];
    });
  });
}

- (void)cancelOverlayFromButton:(UIButton*)button
{
  [self cancelOverlay:button.superview];
}

- (void)cancelOverlay:(UIView*)view
{
  if (view == nil)
    return;
  [UIView animateWithDuration:0.3f
                   animations:^
  {
    view.alpha = 0.0f;
  } completion:^(BOOL finished)
  {
    self.view.userInteractionEnabled = YES;
    [view removeFromSuperview];
  }];
}

#pragma mark - Button Handling

- (void)showFacebookErrorWithTitle:(NSString*)title
                           message:(NSString*)message
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  });
}

- (void)addFacebookContacts:(UIButton*)button
{
  [self setAddContactsButtonHidden:YES];
  __weak InfinitSendRecipientsController* weak_self = self;
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  [manager.login_manager logInWithReadPermissions:kInfinitFacebookReadPermissions
                                          handler:^(FBSDKLoginManagerLoginResult* result,
                                                    NSError* error)
  {
    InfinitSendRecipientsController* strong_self = weak_self;
    if (!error && !result.isCancelled)
    {
      if (![[FBSDKAccessToken currentAccessToken].permissions containsObject:@"user_friends"])
      {
        NSString* title = NSLocalizedString(@"Unable to get friends from Facebook", nil);
        NSString* message =
          NSLocalizedString(@"You need to grant permission to access your friends to find them on Infinit.", nil);
        [strong_self showFacebookErrorWithTitle:title message:message];
        return;
      }
      NSString* token = [FBSDKAccessToken currentAccessToken].tokenString;
      [[InfinitStateManager sharedInstance] addFacebookAccount:token];
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^
    {
      InfinitSendRecipientsController* strong_self = weak_self;
      [strong_self setAddContactsButtonHidden:NO];
      NSString* title = NSLocalizedString(@"Unable to connect with Facebook", nil);
      NSString* message = nil;
      if (error)
        message = error.localizedDescription;
      else if (result.isCancelled)
        message = NSLocalizedString(@"Facebook login cancelled.", nil);
      [strong_self showFacebookErrorWithTitle:title message:message];
    });
  }];
  [self cancelOverlayFromButton:button];
}

- (IBAction)addContactsTapped:(id)sender
{
  [self showImportOverlay];
}

- (IBAction)backButtonTapped:(id)sender
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    if ([InfinitHostDevice iOSVersion] < 8.0f)
      [[UIApplication sharedApplication].windows.firstObject makeKeyAndVisible];
    else
      [self.splitViewController dismissViewControllerAnimated:YES completion:NULL];
    [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:self.managed_files];
    self.managed_files = nil;
  }
  else
  {
    [self.navigationController popViewControllerAnimated:YES];
    Class gallery_class = InfinitSendGalleryController.class;
    if (![self.navigationController.topViewController isKindOfClass:gallery_class])
    {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
      {
        [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:self.managed_files];
        self.managed_files = nil;
      });
    }
    else
    {
      self.managed_files = nil;
    }
  }
}

- (void)doneSending
{
  self.sent_to_contact = NO;
  if (self.managed_files && !self.managed_files.sending)
    self.managed_files.sending = YES;
  dispatch_async(dispatch_get_main_queue(), ^
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      if ([self.parentViewController respondsToSelector:@selector(hideController)])
      {
        [(InfinitOverlayViewController*)self.parentViewController hideController];
      }
      else
      {
        if ([InfinitHostDevice iOSVersion] < 8.0f)
          [[UIApplication sharedApplication].windows.firstObject makeKeyAndVisible];
        else
          [self.splitViewController dismissViewControllerAnimated:YES completion:NULL];
      }
    }
    else
    {
      [((InfinitTabBarController*)self.tabBarController) showMainScreen:self];
    }
  });
}

- (IBAction)sendButtonTapped:(id)sender
{
  [self setSendButtonHidden:YES];
  [self doneSending];
  if (self.recipients.count == 0)
    return;
  void (^send_block)() = ^()
  {
    NSArray* transaction_ids =
      [self sendFilesToCurrentRecipients:self.managed_files.sorted_paths];
    [[InfinitTemporaryFileManager sharedInstance] addTransactionIds:transaction_ids
                                                    forManagedFiles:self.managed_files];
    [[InfinitTemporaryFileManager sharedInstance] markManagedFilesAsSending:self.managed_files];
    InfinitUploadThumbnailManager* thumb_manager = [InfinitUploadThumbnailManager sharedInstance];
    if (self.managed_files.asset_map.count)
    {
      NSMutableArray* ordered_assets = [NSMutableArray array];
      for (NSString* path in self.managed_files.sorted_paths)
      {
        id asset = [self.managed_files.asset_map allKeysForObject:path].firstObject;
        [ordered_assets addObject:asset];
      }
      [thumb_manager generateThumbnailsForAssets:ordered_assets
                          forTransactionsWithIds:transaction_ids];
    }
    else
    {
      [thumb_manager generateThumbnailsForFiles:self.managed_files.sorted_paths
                         forTransactionsWithIds:transaction_ids];
    }
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSend
                               method:InfinitUIMethodTap];
    self.managed_files = nil;
  };
  if (self.managed_files.copying)
  {
    self.managed_files.done_copying_block = send_block;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      if ([InfinitHostDevice iOSVersion] < 8.0f)
        [[UIApplication sharedApplication].windows.firstObject makeKeyAndVisible];
      else
        [self.splitViewController dismissViewControllerAnimated:YES completion:NULL];
      NSString* message = NSLocalizedString(@"Preparing your transfer...", nil);
      [[InfinitStatusBarNotifier sharedInstance] showMessage:message
                                                      ofType:InfinitStatusBarNotificationInfo
                                                    duration:4.0f
                                                withActivity:YES];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      SEL selector = @selector(showTransactionPreparingNotification);
      if ([self.tabBarController respondsToSelector:selector])
      {
        [self.tabBarController performSelector:selector withObject:nil afterDelay:1.0f];
      }
    }
  }
  else
  {
    send_block();
  }
}

- (NSArray*)sendFilesToCurrentRecipients:(NSArray*)files
{
  NSMutableArray* actual_recipients = [NSMutableArray array];
  NSMutableArray* device_specific_recipients = [NSMutableArray array];
  for (InfinitContact* contact in self.recipients)
  {
    if ([contact isKindOfClass:InfinitContactUser.class])
    {
      InfinitContactUser* contact_user = (InfinitContactUser*)contact;
      if (contact_user.infinit_user != nil && contact_user.device == nil)
      {
        if (contact_user.infinit_user.ghost &&
            contact_user.infinit_user.ghost_identifier.infinit_isPhoneNumber &&
            [InfinitHostDevice canSendSMS])
        {
          continue;
        }
        else
        {
          [actual_recipients addObject:contact_user.infinit_user];
        }
      }
      else if (contact_user.infinit_user != nil && contact_user.device != nil)
      {
        [device_specific_recipients addObject:contact_user];
      }
    }
    else if ([contact isKindOfClass:InfinitContactEmail.class])
    {
      InfinitContactEmail* contact_email = (InfinitContactEmail*)contact;
      [actual_recipients addObject:contact_email.email];
    }
    else if ([contact isKindOfClass:InfinitContactAddressBook.class])
    {
      InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)contact;
      [actual_recipients addObject:contact_ab.emails[contact_ab.selected_email_index]];
    }
  }
  NSMutableArray* ids =
    [[[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                  toRecipients:actual_recipients
                                                   withMessage:@""] mutableCopy];
  for (InfinitContactUser* contact in device_specific_recipients)
  {
    NSNumber* id_ = [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                                  toRecipient:contact.infinit_user
                                                                     onDevice:contact.device 
                                                                  withMessage:@""];
    [ids addObject:id_];
  }
  return ids;
}

- (IBAction)importPhoneContactsTapped:(id)sender
{
  [self showAddressBookOverlay];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  if ([self noResults])
    return 1;
  else
    return InfinitSendRecipientsSectionCount;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if ([self noResults])
    return 1;

  switch (section)
  {
    case InfinitSendRecipientsSectionSelf:
      return self.device_results.count;
    case InfinitSendRecipientsSectionSwaggers:
      return self.swagger_results.count;
    case InfinitSendRecipientsSectionContacts:
      return ([self askedForAddressBookAccess] ? self.contact_results.count : 1);

    default:
      return 0;
  }
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* res = nil;
  InfinitContact* contact = nil;
  if (self.email_entered)
  {
    InfinitSendEmailCell* cell = [tableView dequeueReusableCellWithIdentifier:_email_cell_id
                                                                 forIndexPath:indexPath];
    cell.email_label.text = [NSString stringWithFormat:@"\"%@\"", _last_search];
    res = cell;
  }
  else if ([self noResults])
  {
    InfinitSendNoResultsCell* cell =
      [tableView dequeueReusableCellWithIdentifier:_no_results_cell_id forIndexPath:indexPath];
    cell.show_buttons = ![self askedForAddressBookAccess];
    if ([self askedForAddressBookAccess])
    {
      cell.message_label.text =
        NSLocalizedString(@"No one here by that name.\nTry an email instead.", nil);
    }
    else
    {
      cell.message_label.text =
        NSLocalizedString(@"No one here by that name.\nTry connecting your Contacts", nil);
    }
    res = cell;
  }
  else if (indexPath.section == InfinitSendRecipientsSectionSelf)
  {
    if (self.no_devices)
    {
      InfinitSendUserCell* cell = [tableView dequeueReusableCellWithIdentifier:_infinit_user_cell_id
                                                                  forIndexPath:indexPath];
      InfinitContact* contact = self.device_results[indexPath.row];
      cell.contact = contact;
      [cell setSelected:[self.recipients containsObject:contact] animated:NO];
      cell.user_type_view.hidden = NO;
      res = cell;
    }
    else
    {
      InfinitSendDeviceCell* cell = [tableView dequeueReusableCellWithIdentifier:_device_cell_id
                                                                    forIndexPath:indexPath];
      InfinitContactUser* contact = self.device_results[indexPath.row];
      [cell setupForContact:contact];
      if ([self.recipients containsObject:contact])
      {
        [tableView selectRowAtIndexPath:indexPath
                               animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
      }
      else
      {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
      }
      res = cell;
    }
  }
  else if (indexPath.section == InfinitSendRecipientsSectionSwaggers)
  {
    InfinitSendUserCell* cell = [tableView dequeueReusableCellWithIdentifier:_infinit_user_cell_id
                                                                forIndexPath:indexPath];
    InfinitContactUser* contact = self.swagger_results[indexPath.row];
    cell.contact = contact;
    cell.user_type_view.hidden = !contact.infinit_user.favorite;
    if ([self.recipients containsObject:contact])
    {
      [tableView selectRowAtIndexPath:indexPath
                             animated:NO
                       scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
      [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    res = cell;
  }
  else
  {
    if (self.contact_results.count == 0)
    {
      InfinitContactImportCell* cell = [tableView dequeueReusableCellWithIdentifier:_import_cell_id
                                                                    forIndexPath:indexPath];
      [cell.phone_contacts_button addTarget:self
                                     action:@selector(importPhoneContactsTapped:)
                           forControlEvents:UIControlEventTouchUpInside];
      res = cell;
    }
    else
    {
      InfinitSendContactCell* cell = [tableView dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
      contact = self.contact_results[indexPath.row];
      cell.contact = contact;
      if (indexPath.row == 0)
        cell.letter_label.hidden = NO;
      else if (![[[self.contact_results[indexPath.row - 1] fullname] substringToIndex:1].lowercaseString isEqualToString:
                 [[self.contact_results[indexPath.row] fullname] substringToIndex:1].lowercaseString])
        cell.letter_label.hidden = NO;
      else
        cell.letter_label.hidden = YES;
      if ([self.recipients containsObject:contact])
      {
        [tableView selectRowAtIndexPath:indexPath
                               animated:NO 
                         scrollPosition:UITableViewScrollPositionNone];
      }
      else
      {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
      }
      res = cell;
    }
  }
  if ([self.table_view.indexPathsForSelectedRows containsObject:indexPath])
  {
    [self.table_view selectRowAtIndexPath:indexPath
                                 animated:NO
                           scrollPosition:UITableViewScrollPositionNone];
  }
  return res;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  if ([self noResults])
    return 0.0f;

  switch (section)
  {
    case InfinitSendRecipientsSectionSelf:
      if (self.device_results.count > 0)
        break;
      else
        return 0.0f;
    case InfinitSendRecipientsSectionSwaggers:
      if (self.swagger_results.count > 0)
        break;
      else
        return 0.0f;
    case InfinitSendRecipientsSectionContacts:
      if (self.contact_results.count > 0)
        break;
      else
        return 0.0f;

    default:
      break;
  }
  return 1.0f;
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  UIView* res = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,
                                                          tableView.bounds.size.width, 1.0f)];
  CGFloat right = 22.0f;
  CGFloat left = 15.0f;
  UIView* line =
    [[UIView alloc] initWithFrame:CGRectMake(left,
                                             0.0f,
                                             tableView.bounds.size.width - left - right,
                                             1.0f)];
  line.backgroundColor = [InfinitColor colorWithGray:227];
  [res addSubview:line];
  return res;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.email_entered)
    return 62.0f;
  if ([self noResults])
    return 349.0f;
  if (indexPath.section == InfinitSendRecipientsSectionContacts && ![self askedForAddressBookAccess])
    return 349.0f;
  else
    return 62.0f;
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (([self noResults] && !_last_search.infinit_isEmail) ||
      (![self askedForAddressBookAccess] && indexPath.section == InfinitSendRecipientsSectionContacts))
  {
    return NO;
  }
  if (self.recipients.count > _max_recipients)
    return NO;
  return YES;
}

- (void)sendToSelfBlocked
{
  [InfinitQuotaManager showSendToSelfLimitOverlay];
  [[InfinitStateManager sharedInstance] sendMetricSendToSelfLimit];
}

- (NSIndexPath*)tableView:(UITableView*)tableView
 willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitAccountManager* manager = [InfinitAccountManager sharedInstance];
  BOOL reached_self_quota =
    manager.send_to_self_quota.quota && !manager.send_to_self_quota.remaining.unsignedIntegerValue;
  if (self.email_entered)
  {
    if (reached_self_quota)
    {
      if ([[InfinitExternalAccountsManager sharedInstance] userEmail:_last_search])
      {
        [self sendToSelfBlocked];
        return nil;
      }
    }
  }
  else if (indexPath.section == InfinitSendRecipientsSectionSelf)
  {
    if (reached_self_quota)
    {
      [self sendToSelfBlocked];
      return nil;
    }

  }
  else if (indexPath.section == InfinitSendRecipientsSectionContacts)
  {
    InfinitContactAddressBook* contact =
      (InfinitContactAddressBook*)self.contact_results[indexPath.row];
    if (reached_self_quota)
    {
      for (NSString* email in contact.emails)
      {
        if ([[InfinitExternalAccountsManager sharedInstance] userEmail:email])
        {
          [self sendToSelfBlocked];
          return nil;
        }
      }
    }
  }
  return indexPath;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.recipients == nil)
    _recipients = [[NSMutableOrderedSet alloc] init];
  InfinitContact* contact = nil;
  if (self.email_entered)
  {
    [self addContactFromEmailAddress:_last_search];
    _last_search = @"";
    [self.search_field resignFirstResponder];
    return;
  }
  else if (indexPath.section == InfinitSendRecipientsSectionSelf)
  {
    InfinitApplicationSettings* settings = [InfinitApplicationSettings sharedInstance];
    if (![[settings send_to_self_onboarded] isEqualToNumber:@1])
    {
      [settings setSend_to_self_onboarded:@1];
      if ([InfinitDeviceManager sharedInstance].other_devices.count == 0)
        [self showSendToSelfOverlay];
    }
    contact = self.device_results[indexPath.row];
  }
  else if (indexPath.section == InfinitSendRecipientsSectionSwaggers)
  {
    InfinitContactUser* contact_user = (InfinitContactUser*)self.swagger_results[indexPath.row];
    if (contact_user.infinit_user.ghost &&
        contact_user.infinit_user.ghost_identifier.infinit_isPhoneNumber)
    {
      InfinitContactAddressBook* contact_ab =
        [[InfinitContactManager sharedInstance] contactForUser:contact_user.infinit_user];
      if (contact_ab)
        [self overlayForSendToContact:contact_ab];
      else
        contact = contact_user;
    }
    else
    {
      contact = contact_user;
    }
    if (contact_user.infinit_user.favorite)
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSelectFavorite
                                 method:InfinitUIMethodTap];
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSelectSwagger
                                 method:InfinitUIMethodTap];
    }
  }
  else if (indexPath.section == InfinitSendRecipientsSectionContacts)
  {
    InfinitContactAddressBook* contact_ab =
      (InfinitContactAddressBook*)self.contact_results[indexPath.row];
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSelectAddressBookContact
                               method:InfinitUIMethodTap];
    [self overlayForSendToContact:contact_ab];
  }
  if (contact != nil)
    [self.recipients addObject:contact];
  [self updateSendButton];
  [self.search_field reloadData];
  [self reloadSearchResults];
  [self.search_field resignFirstResponder];
}

- (void)tableView:(UITableView*)tableView
didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitContact* contact =
    [(InfinitSendAbstractCell*)([self.table_view cellForRowAtIndexPath:indexPath]) contact];
  [self.recipients removeObject:contact];
  if ([contact isKindOfClass:InfinitContactAddressBook.class])
  {
    InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)contact;
    contact_ab.selected_phone_index = NSNotFound;
    contact_ab.selected_email_index = NSNotFound;
  }
  [self.search_field reloadData];
  [self reloadSearchResults];
  [self updateSendButton];
}

#pragma mark - Text Input Handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - Helpers

- (void)setSendButtonTextToDone:(BOOL)done
{
  NSString* button_text = nil;
  UIImage* button_image = nil;
  if (done)
  {
    button_text = NSLocalizedString(@"DONE", nil);
    button_image = nil;
    self.send_button.titleEdgeInsets = UIEdgeInsetsZero;
  }
  else
  {
    button_text = NSLocalizedString(@"SEND", nil);
    button_image = _send_button_image;
    self.send_button.titleEdgeInsets =
      UIEdgeInsetsMake(0.0f,
                       - self.send_button.imageView.frame.size.width,
                       0.0f,
                       self.send_button.imageView.frame.size.width);
  }
  [self.send_button setTitle:button_text forState:UIControlStateNormal];
  [self.send_button setImage:button_image forState:UIControlStateNormal];
}

- (void)setSendButtonHidden:(BOOL)hidden
{
  CGFloat constraint_final;
  if (hidden)
  {
    self.send_button.enabled = NO;
    self.send_button.hidden = YES;
    constraint_final = - self.send_button.frame.size.height;
  }
  else
  {
    self.send_button.enabled = YES;
    self.send_button.hidden = NO;
    constraint_final = 0.0f;
  }
  if (self.send_constraint.constant == constraint_final)
    return;
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.send_constraint.constant = constraint_final;
     [self.view layoutIfNeeded];
   } completion:^(BOOL finished)
   {
     if (!finished)
       self.send_constraint.constant = constraint_final;
   }];
}

- (void)updateSendButton
{
  if ([self inputsGood] || self.sent_to_contact)
  {
    [self setSendButtonTextToDone:(self.sent_to_contact && self.recipients.count == 0)];
    [self setSendButtonHidden:NO];
  }
  else
  {
    [self setSendButtonHidden:YES];
  }
}

- (BOOL)inputsGood
{
  if (self.recipients.count == 0)
    return NO;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !self.file_count)
    return NO;
  return YES;
}

#pragma mark - Search field delegate

- (void)addContactFromEmailAddress:(NSString*)email
{
  if (self.recipients.count > _max_recipients)
    return;
  InfinitContactEmail* contact = [InfinitContactEmail contactWithEmail:email];
  if (self.recipients == nil)
    self.recipients = [NSMutableOrderedSet orderedSet];
  [self.recipients addObject:contact];
  [self.search_field reloadData];
  [self reloadSearchResults];
  [self updateSendButton];
  [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewEmailAddress 
                             method:InfinitUIMethodType];
}

- (void)tokenField:(VENTokenField*)tokenField
      didEnterText:(NSString*)text
{
  NSString* trimmed_string =
    [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
  if (trimmed_string.infinit_isEmail)
  {
    [self addContactFromEmailAddress:trimmed_string];
  }
  [self.search_field resignFirstResponder];
}

- (void)tokenField:(VENTokenField*)tokenField
didDeleteTokenAtIndex:(NSUInteger)index
{
  InfinitContact* contact = self.recipients[index];
  if ([contact isKindOfClass:InfinitContactAddressBook.class])
  {
    InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)contact;
    contact_ab.selected_email_index = NSNotFound;
    contact_ab.selected_phone_index = NSNotFound;
  }
  if ([contact isEqual:self.me_contact])
  {
    if (self.no_devices)
    {
      NSIndexPath* index = [NSIndexPath indexPathForRow:0
                                              inSection:InfinitSendRecipientsSectionSelf];
      [self.table_view deselectRowAtIndexPath:index animated:YES];
    }
    else
    {
      NSUInteger table_index = [self.device_results indexOfObject:contact];
      NSIndexPath* index = [NSIndexPath indexPathForRow:table_index
                                              inSection:InfinitSendRecipientsSectionSelf];
      [self.table_view deselectRowAtIndexPath:index
                                     animated:YES];
    }
  }
  else if ([self.swagger_results containsObject:contact])
  {
    NSUInteger table_index = [self.swagger_results indexOfObject:contact];
    NSIndexPath* index = [NSIndexPath indexPathForRow:table_index
                                            inSection:InfinitSendRecipientsSectionSwaggers];
    [self.table_view deselectRowAtIndexPath:index animated:YES];
  }
  else if ([self.contact_results containsObject:contact])
  {
    NSUInteger table_index = [self.contact_results indexOfObject:contact];
    NSIndexPath* index = [NSIndexPath indexPathForRow:table_index
                                            inSection:InfinitSendRecipientsSectionContacts];
    [self.table_view deselectRowAtIndexPath:index animated:YES];
  }
  [self.recipients removeObjectAtIndex:index];
  [self.search_field reloadData];
  [self reloadSearchResults];
  [self updateSendButton];
}

- (void)tokenField:(VENTokenField*)tokenField
     didChangeText:(NSString*)text
{
  if (self.last_search.infinit_isEmail &&
      [text rangeOfString:_last_search].location != NSNotFound &&
      [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].location != NSNotFound)
  {
    NSString* email = [_last_search copy];
    self.last_search = @"";
    [self addContactFromEmailAddress:email];
    return;
  }
  if (!text.length)
  {
    [self reloadSearchResults];
    return;
  }
  self.last_search = text.lowercaseString;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(250 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self updateSearchResultsWithSearchString:self.last_search];
  });
}

- (void)tokenFieldDidBeginEditing:(VENTokenField*)tokenField
{
  [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewToField
                             method:InfinitUIMethodTap];
}

#pragma mark - Search field datasource

- (NSString*)tokenField:(VENTokenField*)tokenField
   titleForTokenAtIndex:(NSUInteger)index
{
  InfinitContact* contact = [self.recipients objectAtIndex:index];
  if ([contact isKindOfClass:InfinitContactUser.class])
  {
    InfinitContactUser* contact_user = (InfinitContactUser*)contact;
    if (contact_user.device != nil)
      return contact_user.device_name;
  }
  if (contact.first_name.length)
    return contact.first_name;
  if ([contact isKindOfClass:InfinitContactAddressBook.class])
  {
    InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)contact;
    if (contact_ab.selected_email_index != NSNotFound)
      return contact_ab.emails[contact_ab.selected_email_index];
    else if (contact_ab.selected_phone_index != NSNotFound)
      return contact_ab.phone_numbers[contact_ab.selected_phone_index];
  }
  if ([contact isKindOfClass:InfinitContactEmail.class])
  {
    InfinitContactEmail* contact_email = (InfinitContactEmail*)contact;
    return contact_email.email;
  }
  return NSLocalizedString(@"Unknown", nil);
}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField*)tokenField
{
  return self.recipients.count;
}

- (NSString*)tokenFieldCollapsedText:(VENTokenField*)tokenField
{
  return @"";
}

#pragma mark - Search

- (void)reloadSearchResults
{
  self.email_entered = NO;
  BOOL were_no_results = [self noResults];
  NSMutableIndexSet* sections = [NSMutableIndexSet indexSet];
  if (![self.device_results isEqualToArray:self.all_devices])
  {
    self.device_results = [self.all_devices mutableCopy];
    [sections addIndex:InfinitSendRecipientsSectionSelf];
  }
  if (![self.swagger_results isEqualToArray:self.all_swaggers])
  {
    self.swagger_results = [self.all_swaggers mutableCopy];
    [sections addIndex:InfinitSendRecipientsSectionSwaggers];
  }
  if (![self.contact_results isEqualToArray:self.all_contacts])
  {
    self.contact_results = [self.all_contacts mutableCopy];
    [sections addIndex:InfinitSendRecipientsSectionContacts];
  }
  if (were_no_results || [self noResults])
    [self.table_view reloadData];
  else if (sections.count > 0)
   [self reloadTableSections:sections];
}

- (void)updateSearchResultsWithSearchString:(NSString*)search_string
{
  @synchronized(self)
  {
    if (![self.last_search isEqualToString:search_string])
      return;
    if (self.preloading_contacts)
    {
      [self performSelector:@selector(updateSearchResultsWithSearchString:)
                 withObject:search_string
                 afterDelay:0.3f];
      return;
    }
    self.email_entered = NO;
    BOOL were_no_results = [self noResults];
    NSMutableArray* devices_temp = [NSMutableArray array];
    for (InfinitContact* device in self.all_devices)
    {
      if ([device containsSearchString:search_string])
        [devices_temp addObject:device];
    }
    NSMutableArray* swaggers_temp = [NSMutableArray array];
    for (InfinitContact* contact in self.all_swaggers)
    {
      if ([contact containsSearchString:search_string])
        [swaggers_temp addObject:contact];
    }
    NSMutableArray* contacts_temp = [NSMutableArray array];
    for (InfinitContact* contact in self.all_contacts)
    {
      if ([contact containsSearchString:search_string])
        [contacts_temp addObject:contact];
    }
    NSMutableIndexSet* sections = [NSMutableIndexSet indexSet];
    if (![self.device_results isEqualToArray:devices_temp])
    {
      self.device_results = devices_temp;
      [sections addIndex:InfinitSendRecipientsSectionSelf];
    }
    if (![self.swagger_results isEqualToArray:swaggers_temp])
    {
      self.swagger_results = swaggers_temp;
      [sections addIndex:InfinitSendRecipientsSectionSwaggers];
    }
    if (![self.contact_results isEqualToArray:contacts_temp])
    {
      self.contact_results = contacts_temp;
      [sections addIndex:InfinitSendRecipientsSectionContacts];
    }
    if ((were_no_results || [self noResults]) && !search_string.infinit_isEmail)
    {
      [self.table_view reloadData];
    }
    else if ([self noResults] && search_string.infinit_isEmail)
    {
      self.email_entered = YES;
      if (self.table_view.numberOfSections == 1)
      {
        [self reloadTableSections:[NSIndexSet indexSetWithIndex:InfinitSendRecipientsSectionSelf]];
      }
      else
      {
        [self.table_view reloadData];
      }
    }
    else if (sections.count > 0)
    {
      [self reloadTableSections:sections];
    }
  }
}

#pragma mark - New User

- (void)newUserAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  if (id_.unsignedIntegerValue == 0)
    return;
  InfinitContactUser* contact =
    [InfinitContactUser contactWithInfinitUser:[InfinitUserManager userWithId:id_]];
  self.all_swaggers = [self swaggers];
  if (self.last_search.length)
    return;
  [self.table_view beginUpdates];
  [self.swagger_results insertObject:contact atIndex:0];
  NSIndexPath* index =
    [NSIndexPath indexPathForRow:0 inSection:InfinitSendRecipientsSectionSwaggers];
  [self.table_view insertRowsAtIndexPaths:@[index]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
  [self.table_view endUpdates];
}

#pragma mark - User Avatar

- (void)userAvatarFetched:(NSNotification*)notification
{
  NSNumber* updated_id = notification.userInfo[kInfinitUserId];
  if ([self.me_contact.infinit_user.id_ isEqual:updated_id] && self.no_devices)
  {
    NSIndexPath* path = [NSIndexPath indexPathForRow:0 inSection:InfinitSendRecipientsSectionSelf];
    InfinitSendUserCell* cell = (InfinitSendUserCell*)[self.table_view cellForRowAtIndexPath:path];
    dispatch_async(dispatch_get_main_queue(), ^
    {
      [cell updateAvatar];
    });
    return;
  }
  else if ([self.me_contact.infinit_user.id_ isEqual:updated_id])
  {
    // Don't need to update our avatar.
    return;
  }
  [self.swagger_results enumerateObjectsUsingBlock:^(InfinitContactUser* contact,
                                                     NSUInteger idx,
                                                     BOOL* stop)
  {
    if ([contact.infinit_user.id_ isEqualToNumber:updated_id])
    {
      NSIndexPath* path = [NSIndexPath indexPathForRow:idx
                                             inSection:InfinitSendRecipientsSectionSwaggers];
      InfinitSendUserCell* cell =
        (InfinitSendUserCell*)[self.table_view cellForRowAtIndexPath:path];
      dispatch_async(dispatch_get_main_queue(), ^
      {
        [cell updateAvatar];
      });
      *stop = YES;
      return;
    }
  }];
}

#pragma mark - Managed Files Deleted

- (void)managedFilesDeleted:(NSNotification*)notification
{
  NSString* uuid = notification.userInfo[kInfinitManagedFilesId];
  if ([uuid isEqualToString:self.managed_files.uuid])
  {
    [self doneSending];
    self.managed_files = nil;
  }
}

#pragma mark - Handle Address Book Contact Send

- (void)overlayForSendToContact:(InfinitContactAddressBook*)contact
{
  if (![contact isKindOfClass:InfinitContactAddressBook.class])
    return;
  InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)contact;
  self.invitation_overlay.contact = contact_ab;
  self.view.userInteractionEnabled = NO;
  UIView* view = self.invitation_overlay.view;
  view.alpha = 0.0f;
  view.frame = [UIScreen mainScreen].bounds;
  [[UIApplication sharedApplication].keyWindow addSubview:view];
  [self.invitation_overlay awakeFromNib];
  [[UIApplication sharedApplication].keyWindow bringSubviewToFront:view];
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 1.0f;
   } completion:^(BOOL finished)
   {
     if (!finished)
       view.alpha = 1.0f;
   }];
}

- (void)removeInvitationOverlay
{
  UIView* view = self.invitation_overlay.view;
  InfinitContactAddressBook* contact_ab = self.invitation_overlay.contact;
  NSUInteger row = [self.contact_results indexOfObject:contact_ab];
  if (row != NSNotFound)
  {
    NSIndexPath* index = [NSIndexPath indexPathForRow:row
                                            inSection:InfinitSendRecipientsSectionContacts];
    if ([self.table_view.indexPathsForSelectedRows containsObject:index])
      [self.table_view deselectRowAtIndexPath:index animated:NO];
    else
      row = NSNotFound;
  }
  if (row == NSNotFound)
  {
    [self.swagger_results enumerateObjectsUsingBlock:^(InfinitContactUser* contact_user,
                                                       NSUInteger i,
                                                       BOOL* stop)
    {
      if (contact_user.infinit_user.ghost)
      {
        NSString* identifier =
          [contact_user.infinit_user.ghost_identifier stringByReplacingOccurrencesOfString:@" "
                                                                                withString:@""];
        if ([contact_ab.phone_numbers indexOfObject:identifier] != NSNotFound ||
            [contact_ab.emails indexOfObject:identifier] != NSNotFound)
        {
          NSIndexPath* index = [NSIndexPath indexPathForRow:i
                                                  inSection:InfinitSendRecipientsSectionSwaggers];
          if ([self.table_view.indexPathsForSelectedRows containsObject:index])
          {
            [self.table_view deselectRowAtIndexPath:index animated:NO];
            *stop = YES;
          }
        }
      }
    }];
  }
  if (view == nil)
    return;
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 0.0f;
   } completion:^(BOOL finished)
   {
     self.view.userInteractionEnabled = YES;
     [view removeFromSuperview];
     self.invitation_overlay.loading = NO;
   }];
}

- (InfinitInvitationOverlayViewController*)invitation_overlay
{
  dispatch_once(&_invitation_overlay_token, ^
  {
    _invitation_overlay = [[InfinitInvitationOverlayViewController alloc] init];
    _invitation_overlay.delegate = self;
  });
  return _invitation_overlay;
}

- (void)invitationOverlay:(InfinitInvitationOverlayViewController*)sender
             gotRecipient:(InfinitMessagingRecipient*)recipient
{
  if (!self.invitation_overlay.loading)
    self.invitation_overlay.loading = YES;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    [self.recipients addObject:self.invitation_overlay.contact];
    [self.search_field reloadData];
    [self updateSendButton];
    [self removeInvitationOverlay];
    return;
  }
  if (self.managed_files.copying)
  {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^
    {
      [self invitationOverlay:sender gotRecipient:recipient];
    });
    return;
  }
  self.current_message_recipient = recipient;
  NSArray* transaction_ids =
    [[InfinitPeerTransactionManager sharedInstance] sendFiles:self.managed_files.sorted_paths
                                                 toRecipients:@[recipient.identifier]
                                                  withMessage:@""];
  [[InfinitTemporaryFileManager sharedInstance] addTransactionIds:transaction_ids
                                                  forManagedFiles:self.managed_files];
  InfinitUploadThumbnailManager* thumb_manager = [InfinitUploadThumbnailManager sharedInstance];
  if (self.managed_files.asset_map.count)
  {
    NSMutableArray* ordered_assets = [NSMutableArray array];
    for (NSString* path in self.managed_files.sorted_paths)
    {
      id asset = [self.managed_files.asset_map allKeysForObject:path].firstObject;
      [ordered_assets addObject:asset];
    }
    [thumb_manager generateThumbnailsForAssets:ordered_assets
                        forTransactionsWithIds:transaction_ids];
  }
  else
  {
    [thumb_manager generateThumbnailsForFiles:self.managed_files.sorted_paths
                       forTransactionsWithIds:transaction_ids];
  }
  [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSend
                             method:InfinitUIMethodTap];
}

- (void)handleGhostTransaction:(NSNotification*)notification
{
  @synchronized(self)
  {
    NSDictionary* dict = notification.userInfo;
    InfinitPeerTransaction* transaction =
      [[InfinitPeerTransactionManager sharedInstance] transactionWithId:dict[kInfinitTransactionId]];
    if (transaction == nil)
      return;
    InfinitUser* recipient_user = transaction.recipient;
    if (self.current_message_recipient.method == InfinitMessageEmail)
    {
      [self removeInvitationOverlay];
      self.sent_to_contact = YES;
      dispatch_async(dispatch_get_main_queue(), ^
      {
        [self updateSendButton];
      });
      return;
    }
    if (!recipient_user.ghost_code.length || !recipient_user.ghost_invitation_url.length)
    {
      [self removeInvitationOverlay];
      return;
    }
    NSString* message = recipient_user.ghost_invitation_url;
    [self removeInvitationOverlay];
    if (self.current_message_recipient.method == InfinitMessageNative &&
        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      if ([self.navigationController isKindOfClass:InfinitSendNavigationController.class])
      {
        ((InfinitSendNavigationController*)self.navigationController).smsing = YES;
      }
    }
    [[InfinitMessagingManager sharedInstance] sendMessage:message
                                              toRecipient:self.current_message_recipient
                                          completionBlock:^(InfinitMessagingRecipient* recipient,
                                                            NSString* message,
                                                            InfinitMessageStatus status)
    {
      if (recipient.method == InfinitMessageNative || recipient.method == InfinitMessageWhatsApp)
      {
        switch (status)
        {
          case InfinitMessageStatusCancel:
            [InfinitMetricsManager sendMetricGhostSMSSent:NO
                                                     code:recipient_user.ghost_code
                                               failReason:@"cancel"];
            break;
          case InfinitMessageStatusFail:
            [InfinitMetricsManager sendMetricGhostSMSSent:NO
                                                     code:recipient_user.ghost_code
                                               failReason:@"fail"];
            break;
          case InfinitMessageStatusSuccess:
            [InfinitMetricsManager sendMetricGhostSMSSent:YES
                                                     code:recipient_user.ghost_code
                                               failReason:nil];
            break;
        }
      }
      if (recipient.method == InfinitMessageNative && status != InfinitMessageStatusSuccess)
      {
        [[InfinitStateManager sharedInstance] sendInvitation:recipient.identifier
                                                     message:message
                                                   ghostCode:transaction.recipient.ghost_code
                                                  userCancel:(status == InfinitMessageStatusCancel)
                                                        type:@"ghost"];
      }
      self.sent_to_contact = YES;
      dispatch_async(dispatch_get_main_queue(), ^
      {
        [self updateSendButton];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
          if ([self.navigationController isKindOfClass:InfinitSendNavigationController.class])
          {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationSlide];
            ((InfinitSendNavigationController*)self.navigationController).smsing = NO;
          }
        }
      });
    }];
  }
}

- (void)invitationOverlayGotCancel:(InfinitInvitationOverlayViewController*)sender
{
  [self removeInvitationOverlay];
}

#pragma mark - Helpers

- (BOOL)noResults
{
  return (self.device_results.count == 0 &&
          self.swagger_results.count == 0 &&
          self.contact_results.count == 0);
}

- (BOOL)askedForAddressBookAccess
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    return NO;
  return YES;
}

- (BOOL)can_send_sms
{
  return [InfinitHostDevice canSendSMS];
}

@end
