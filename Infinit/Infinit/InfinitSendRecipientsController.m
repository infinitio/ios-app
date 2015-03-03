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
#import "InfinitColor.h"
#import "InfinitContact.h"
#import "InfinitImportOverlayView.h"
#import "InfinitSendContactCell.h"
#import "InfinitContactImportCell.h"
#import "InfinitMetricsManager.h"
#import "InfinitSendEmailCell.h"
#import "InfinitSendNoResultsCell.h"
#import "InfinitSendToSelfOverlayView.h"
#import "InfinitSendUserCell.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitUserManager.h>

#import "NSString+email.h"
#import "VENTokenField.h"

@import AddressBook;
@import AssetsLibrary;
@import Photos;

@interface InfinitSendRecipientsController () <UIActionSheetDelegate,
                                               UITextFieldDelegate,
                                               UIGestureRecognizerDelegate,
                                               VENTokenFieldDelegate,
                                               VENTokenFieldDataSource>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* invite_button;
@property (nonatomic, weak) IBOutlet VENTokenField* search_field;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UIButton* send_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_constraint;

@property (nonatomic, strong) InfinitAccessContactsView* contacts_overlay;
@property (nonatomic, strong) InfinitImportOverlayView* import_overlay;
@property (nonatomic, strong) InfinitSendToSelfOverlayView* send_to_self_overlay;

@property (nonatomic, strong) InfinitContact* me_contact;
@property (nonatomic) BOOL me_match;
@property (nonatomic) BOOL email_entered;
@property (nonatomic, strong) NSMutableArray* all_swaggers;
@property (nonatomic, strong) NSMutableArray* swagger_results;
@property (nonatomic, strong) NSMutableArray* all_contacts;
@property (nonatomic, strong) NSMutableArray* contact_results;
@property (nonatomic, strong) NSMutableOrderedSet* recipients;

@end

@implementation InfinitSendRecipientsController
{
@private
  NSString* _managed_files_id;

  NSString* _me_cell_id;
  NSString* _email_cell_id;
  NSString* _infinit_user_cell_id;
  NSString* _contact_cell_id;
  NSString* _import_cell_id;
  NSString* _no_results_cell_id;

  NSString* _last_search;
  UITapGestureRecognizer* _nav_bar_tap;
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _me_cell_id = @"send_user_me_cell";
    _email_cell_id = @"send_email_cell";
    _infinit_user_cell_id = @"send_user_infinit_cell";
    _contact_cell_id = @"send_contact_cell";
    _import_cell_id = @"contact_import_cell";
    _no_results_cell_id = @"send_no_results_cell";
    _nav_bar_tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(navBarTapped)];
  }
  return self;
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
  [self.invite_button setTitleTextAttributes:nav_bar_attrs forState:UIControlStateNormal];
  self.table_view.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.table_view.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
}

- (void)configureSearchField
{
  if (self.swagger_results.count > 1)
    self.search_field.placeholderText = NSLocalizedString(@"Search contacts by name or email...", nil);
  else
    self.search_field.placeholderText = NSLocalizedString(@"Type email or send to yourself...", nil);
  self.search_field.toLabelTextColor = [UIColor blackColor];
  self.search_field.maxHeight = 112.0f;
  self.search_field.delegate = self;
  self.search_field.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
  _me_match = YES;
  [self fetchSwaggers];
  [self configureSearchField];
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userAvatarFetched:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  _managed_files_id = [[InfinitTemporaryFileManager sharedInstance] createManagedFiles];
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    [self performSelectorInBackground:@selector(fetchAddressBook) withObject:nil];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:_nav_bar_tap];
  if (self.recipient != nil)
  {
    NSUInteger section = NSNotFound;
    NSUInteger row = NSNotFound;
    if (self.recipient.infinit_user != nil)
    {
      if (self.recipient.infinit_user.is_self)
      {
        section = 0;
        row = 0;
      }
      else
      {
        section = 1;
        row = [self.swagger_results indexOfObject:self.recipient];
      }
    }
    else
    {
      section = 2;
      row = [self.contact_results indexOfObject:self.recipient];
    }
    if (section != NSNotFound && row != NSNotFound)
    {
      NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:section];
      [self.table_view selectRowAtIndexPath:path
                                   animated:NO
                             scrollPosition:UITableViewScrollPositionNone];
      [self tableView:self.table_view didSelectRowAtIndexPath:path];
    }
  }
}

- (void)navBarTapped
{
  [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  _recipient = nil;
  _files = nil;
  _assets = nil;
  [self.navigationController.navigationBar.subviews[0] removeGestureRecognizer:_nav_bar_tap];
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - General

- (void)resetView
{
  self.assets = nil;
  self.files = nil;
  [self.recipients removeAllObjects];
}

- (void)fetchSwaggers
{
  InfinitUserManager* manager = [InfinitUserManager sharedInstance];
  self.me_contact = [[InfinitContact alloc] initWithInfinitUser:[manager me]];
  self.all_swaggers = [NSMutableArray array];
  for (InfinitUser* user in [manager favorites])
  {
    if (!user.ghost && !user.deleted)
      [self.all_swaggers addObject:[[InfinitContact alloc] initWithInfinitUser:user]];
  }
  for (InfinitUser* user in [manager time_ordered_swaggers])
  {
    if (!user.ghost && !user.deleted)
      [self.all_swaggers addObject:[[InfinitContact alloc] initWithInfinitUser:user]];
  }
  self.swagger_results = [self.all_swaggers copy];
  [self.table_view reloadData];
}

- (void)fetchAddressBook
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    CFErrorRef* error = nil;
    ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, error);
    self.all_contacts = [NSMutableArray array];
    CFArrayRef sources = ABAddressBookCopyArrayOfAllSources(address_book);
    for (int i = 0; i < CFArrayGetCount(sources); i++)
    {
      ABRecordRef source = CFArrayGetValueAtIndex(sources, i);
      CFArrayRef contacts =
        ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(address_book,
                                                                  source,
                                                                  kABPersonSortByFirstName);
      for (int i = 0; i < CFArrayGetCount(contacts); i++)
      {
        ABRecordRef person = CFArrayGetValueAtIndex(contacts, i);
        if (person)
        {
          InfinitContact* contact = [[InfinitContact alloc] initWithABRecord:person];
          if (contact != nil && contact.emails.count > 0)
            [self.all_contacts addObject:contact];
        }
      }
      CFRelease(contacts);
    }
    CFRelease(sources);
    CFRelease(address_book);
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"fullname"
                                                         ascending:YES
                                                          selector:@selector(caseInsensitiveCompare:)];
    [self.all_contacts sortUsingDescriptors:@[sort]];
    self.contact_results = [self.all_contacts mutableCopy];
    [self performSelectorOnMainThread:@selector(reloadTableSections:)
                           withObject:[NSIndexSet indexSetWithIndex:2]
                        waitUntilDone:NO];
  }
}

- (void)reloadTableSections:(NSIndexSet*)set
{
  [self.table_view reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Overlays

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

- (void)showImportOverlay
{
  if (self.import_overlay == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:NSStringFromClass(InfinitImportOverlayView.class)
                                        bundle:nil];
    self.import_overlay = [[overlay_nib instantiateWithOwner:self options:nil] firstObject];
    [self.import_overlay.phone_contacts_button addTarget:self
                                                  action:@selector(accessAddressBook:)
                                        forControlEvents:UIControlEventTouchUpInside];
    [self.import_overlay.back_button addTarget:self
                                        action:@selector(cancelOverlayFromButton:)
                              forControlEvents:UIControlEventTouchUpInside];
  }
  [self showOverlayView:self.import_overlay];
}

- (void)showSendToSelfOverlay
{
  if (self.send_to_self_overlay == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSendToSelfOverlayView.class)
                                        bundle:nil];
    self.send_to_self_overlay = [[overlay_nib instantiateWithOwner:self options:nil] firstObject];
    [self.send_to_self_overlay.already_infinit_button addTarget:self
                                                         action:@selector(cancelOverlayFromButton:)
                                    forControlEvents:UIControlEventTouchUpInside];
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
  [UIView animateWithDuration:0.5f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
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
    NSLocalizedString(@"Tap \"OK\" so we can display\nyour contacts.", nil);
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
      [self performSelectorOnMainThread:@selector(fetchAddressBook) withObject:nil waitUntilDone:NO];
      [InfinitMetricsManager sendMetric:InfinitUIEventAccessContacts method:InfinitUIMethodYes];
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventAccessContacts method:InfinitUIMethodNo];
    }
    [self performSelectorOnMainThread:@selector(cancelOverlayFromButton:)
                           withObject:sender
                        waitUntilDone:NO];
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
  [UIView animateWithDuration:0.5f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
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

- (IBAction)backButtonTapped:(id)sender
{
  [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:_managed_files_id];
  [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendButtonTapped:(id)sender
{
  [self setSendButtonHidden:YES];
  if (self.assets.count > 0)
  {
    InfinitTemporaryFileManager* manager = [InfinitTemporaryFileManager sharedInstance];
    if ([PHAsset class])
    {
      [manager addPHAssetsLibraryURLList:self.assets
                          toManagedFiles:_managed_files_id
                         performSelector:@selector(temporaryFileManagerCallback)
                                onObject:self];
    }
    else
    {
      NSMutableArray* asset_urls = [NSMutableArray array];
      for (ALAsset* asset in self.assets)
      {
        [asset_urls addObject:asset.defaultRepresentation.url];
      }
      [manager addALAssetsLibraryURLList:asset_urls
                          toManagedFiles:_managed_files_id
                         performSelector:@selector(temporaryFileManagerCallback)
                                onObject:self];
    }
    if (self.assets.count > 3)
    {
      [self.tabBarController performSelectorOnMainThread:@selector(showTransactionPreparingNotification)
                                              withObject:nil 
                                           waitUntilDone:NO];
    }
  }
  else if (self.files.count > 0)
  {
    [self sendFilesToCurrentRecipients:self.files];
  }
  [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSend method:InfinitUIMethodTap];
  [self.tabBarController performSelectorOnMainThread:@selector(showMainScreen:)
                                          withObject:self
                                       waitUntilDone:NO];
}

- (void)temporaryFileManagerCallback
{
  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];
  NSArray* ids = [self sendFilesToCurrentRecipients:files];
  [[InfinitTemporaryFileManager sharedInstance] setTransactionIds:ids
                                                  forManagedFiles:_managed_files_id];
}

- (NSArray*)sendFilesToCurrentRecipients:(NSArray*)files
{
  NSMutableArray* actual_recipients = [NSMutableArray array];
  for (InfinitContact* contact in self.recipients)
  {
    if (contact.infinit_user != nil)
      [actual_recipients addObject:contact.infinit_user];
    else
      [actual_recipients addObject:contact.emails[contact.selected_email_index]];
  }
  return [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                      toRecipients:actual_recipients
                                                       withMessage:@""];
}

- (IBAction)inviteBarButtonTapped:(id)sender
{
  [self showImportOverlay];
}

- (IBAction)importPhoneContactsTapped:(id)sender
{
  [self showAddressBookOverlay];
}

- (IBAction)findFacebookFriendsTapped:(id)sender
{
  
}

- (IBAction)findPeopleOnInfinitTapped:(id)sender
{
  
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  if ([self noResults])
    return 1;
  else
    return 3;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if ([self noResults])
    return 1;

  switch (section)
  {
    case 0:
      return self.me_match ? 1 : 0;
    case 1:
      return self.swagger_results.count;
    case 2:
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
  else if (indexPath.section == 0)
  {
    InfinitSendUserCell* cell = [tableView dequeueReusableCellWithIdentifier:_me_cell_id
                                                                forIndexPath:indexPath];
    cell.contact = self.me_contact;
    cell.user_type_view.hidden = NO;
    res = cell;
  }
  else if (indexPath.section == 1)
  {
    InfinitSendUserCell* cell = [tableView dequeueReusableCellWithIdentifier:_infinit_user_cell_id
                                                                forIndexPath:indexPath];
    cell.contact = self.swagger_results[indexPath.row];
    cell.user_type_view.hidden = !cell.contact.infinit_user.favorite;
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
      res = cell;
    }
  }
  if ([self.recipients containsObject:contact])
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
    case 0:
      if (_me_match)
        break;
      else
        return 0.0f;
    case 1:
      if (self.swagger_results.count > 0)
        break;
      else
        return 0.0f;
    case 2:
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
  UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,
                                                            tableView.bounds.size.width, 1.0f)];
  CGFloat right = 22.0f;
  CGFloat left = 15.0f;
  UIView* line = [[UIView alloc] initWithFrame:CGRectMake(left,
                                                          0.0f,
                                                          tableView.bounds.size.width - left - right,
                                                          1.0f)];
  line.backgroundColor = [InfinitColor colorWithGray:227];
  [header addSubview:line];
  return header;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.email_entered)
    return 62.0f;
  if ([self noResults])
    return 349.0f;
  if (indexPath.section == 2 && ![self askedForAddressBookAccess])
    return 349.0f;
  else
    return 62.0f;
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (([self noResults] && !_last_search.isEmail) ||
      (![self askedForAddressBookAccess] && indexPath.section == 2))
  {
    return NO;
  }
  return YES;
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
  else if (indexPath.section == 0)
  {
    InfinitApplicationSettings* settings = [InfinitApplicationSettings sharedInstance];
    if (![[settings send_to_self_onboarded] isEqualToNumber:@1])
    {
      [settings setSend_to_self_onboarded:@1];
      [self showSendToSelfOverlay];
    }
    contact = self.me_contact;
  }
  else if (indexPath.section == 1)
  {
    contact = self.swagger_results[indexPath.row];
    if (contact.infinit_user.favorite)
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
  else if (indexPath.section == 2)
  {
    contact = self.contact_results[indexPath.row];
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSelectAddressBookContact
                               method:InfinitUIMethodTap];
    if (contact.emails.count == 1)
    {
      contact.selected_email_index = 0;
    }
    else
    {
      UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:nil];
      for (NSString* email in contact.emails)
      {
        [sheet addButtonWithTitle:email];
      }
      [sheet showFromTabBar:self.tabBarController.tabBar];
    }
  }
  if (contact != nil)
    [_recipients addObject:contact];
  [self updateSendButton];
  [self.search_field reloadData];
  [self reloadSearchResults];
  [self.search_field resignFirstResponder];
}

- (void)actionSheetCancel:(UIActionSheet*)actionSheet
{
  InfinitContact* contact = self.recipients.lastObject;
  [self.recipients removeObject:contact];
  [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.contact_results
                                                                        indexOfObject:contact]
                                                             inSection:2]
                                 animated:NO];
  [self.search_field reloadData];
  [self updateSendButton];
}

- (void)actionSheet:(UIActionSheet*)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == actionSheet.cancelButtonIndex)
  {
    InfinitContact* contact = self.recipients.lastObject;
    [self.recipients removeObject:contact];
    [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.contact_results
                                                                          indexOfObject:contact]
                                                               inSection:2]
                                   animated:YES];
    [self.search_field reloadData];
  }
  else
  {
    NSUInteger email_index = buttonIndex - 1;
    InfinitContact* contact = self.recipients.lastObject;
    contact.selected_email_index = email_index;
  }
  [self updateSendButton];
}

- (void)tableView:(UITableView*)tableView
didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitContact* contact =
    [(InfinitSendAbstractCell*)([self.table_view cellForRowAtIndexPath:indexPath]) contact];
  [_recipients removeObject:contact];
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
  if ([self inputsGood])
    [self setSendButtonHidden:NO];
  else
    [self setSendButtonHidden:YES];
}

- (BOOL)inputsGood
{
  if ((self.assets.count == 0 && self.files.count == 0) || self.recipients.count == 0)
    return NO;
  return YES;
}

#pragma mark - Search field delegate

- (void)addContactFromEmailAddress:(NSString*)email
{
  InfinitContact* contact = [[InfinitContact alloc] initWithEmail:email];
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
  if (trimmed_string.isEmail)
  {
    [self addContactFromEmailAddress:trimmed_string];
  }
  [self.search_field resignFirstResponder];
}

- (void)tokenField:(VENTokenField*)tokenField
didDeleteTokenAtIndex:(NSUInteger)index
{
  InfinitContact* contact = self.recipients[index];
  if ([contact isEqual:self.me_contact])
  {
    [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                   animated:YES];
  }
  else if ([self.swagger_results containsObject:contact])
  {
    NSUInteger table_index = [self.swagger_results indexOfObject:contact];
    [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:table_index inSection:1]
                                   animated:YES];
  }
  else if ([self.contact_results containsObject:contact])
  {
    NSUInteger table_index = [self.contact_results indexOfObject:contact];
    [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:table_index inSection:2]
                                   animated:YES];
  }
  [self.recipients removeObjectAtIndex:index];
  [self.search_field reloadData];
  [self reloadSearchResults];
  [self updateSendButton];
}

- (void)tokenField:(VENTokenField*)tokenField
     didChangeText:(NSString*)text
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(updateSearchResultsWithSearchString:)
                                             object:_last_search];
  if (_last_search.isEmail &&
      [text rangeOfString:_last_search].location != NSNotFound &&
      [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].location != NSNotFound)
  {
    NSString* email = [_last_search copy];
    _last_search = @"";
    [self addContactFromEmailAddress:email];
    return;
  }
  _last_search = text;
  if (text.length == 0)
  {
    [self reloadSearchResults];
    return;
  }
  [self performSelector:@selector(updateSearchResultsWithSearchString:)
             withObject:text.lowercaseString
             afterDelay:0.3f];
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
  return [[self.recipients objectAtIndex:index] first_name];
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
  if (!_me_match)
  {
    _me_match = YES;
    [sections addIndex:0];
  }
  if (![self.swagger_results isEqualToArray:self.all_swaggers])
  {
    self.swagger_results = [self.all_swaggers copy];
    [sections addIndex:1];
  }
  if (![self.contact_results isEqualToArray:self.all_contacts])
  {
    self.contact_results = [self.all_contacts copy];
    [sections addIndex:2];
  }
  if (were_no_results || [self noResults])
    [self.table_view reloadData];
  else if (sections.count > 0)
    [self.table_view reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateSearchResultsWithSearchString:(NSString*)search_string
{
  self.email_entered = NO;
  BOOL were_no_results = [self noResults];
  if ([self.me_contact containsSearchString:search_string])
    _me_match = YES;
  else
    _me_match = NO;
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
  [sections addIndex:0];
  if (![self.swagger_results isEqualToArray:swaggers_temp])
  {
    self.swagger_results = swaggers_temp;
    [sections addIndex:1];
  }
  if (![self.contact_results isEqualToArray:contacts_temp])
  {
    self.contact_results = contacts_temp;
    [sections addIndex:2];
  }
  if ((were_no_results || [self noResults]) && !search_string.isEmail)
  {
    [self.table_view reloadData];
  }
  else if ([self noResults] && search_string.isEmail)
  {
    self.email_entered = YES;
    [self.table_view reloadSections:[NSIndexSet indexSetWithIndex:0]
                   withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  else if (sections.count > 0)
  {

    [self.table_view reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - User Avatar

- (void)userAvatarFetched:(NSNotification*)notification
{
  NSNumber* updated_id = notification.userInfo[@"id"];
  if ([self.me_contact.infinit_user.id_ isEqual:updated_id])
  {
    NSIndexPath* path = [NSIndexPath indexPathForRow:0 inSection:0];
    InfinitSendUserCell* cell = (InfinitSendUserCell*)[self.table_view cellForRowAtIndexPath:path];
    [cell performSelectorOnMainThread:@selector(updateAvatar) withObject:nil waitUntilDone:NO];
    return;
  }
  NSUInteger row = 0;
  for (InfinitContact* contact in self.swagger_results)
  {
    if ([contact.infinit_user.id_ isEqualToNumber:updated_id])
    {
      NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:1];
      InfinitSendUserCell* cell = (InfinitSendUserCell*)[self.table_view cellForRowAtIndexPath:path];
      [cell performSelectorOnMainThread:@selector(updateAvatar) withObject:nil waitUntilDone:NO];
      return;
    }
    row++;
  }
}

#pragma mark - Helpers

- (BOOL)noResults
{
  return (!_me_match &&
          self.swagger_results.count == 0 &&
          self.contact_results.count == 0);
}

- (BOOL)askedForAddressBookAccess
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    return NO;
  return YES;
}

@end
