//
//  InfinitSendRecipientsController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendRecipientsController.h"

#import <AddressBook/AddressBook.h>

#import "InfinitAccessContactsView.h"
#import "InfinitColor.h"
#import "InfinitContact.h"
#import "InfinitImportOverlayView.h"
#import "InfinitSendContactCell.h"
#import "InfinitSendImportCell.h"
#import "InfinitSendUserCell.h"
#import "InfinitSendTableHeader.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitUserManager.h>

#import "NSString+email.h"
#import "VENTokenField.h"

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
@property (nonatomic, strong) NSMutableArray* all_contacts;
@property (nonatomic, strong) NSArray* contact_results;
@property (nonatomic, strong) NSMutableOrderedSet* recipients;
@property (nonatomic, strong) NSMutableArray* all_swaggers;
@property (nonatomic, strong) NSArray* swagger_results;

@end

@implementation InfinitSendRecipientsController
{
@private
  NSString* _managed_files_id;

  NSString* _contact_cell_id;
  NSString* _import_cell_id;
  NSString* _user_cell_id;

  NSString* _last_search;
  UITapGestureRecognizer* _nav_bar_tap;
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _contact_cell_id = @"send_contact_cell";
    _import_cell_id = @"send_import_cell";
    _user_cell_id = @"send_user_cell";
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

  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  [self.invite_button setTitleTextAttributes:nav_bar_attrs forState:UIControlStateNormal];
}

- (void)configureSearchField
{
  if (self.swagger_results.count > 1 && self.contact_results.count > 0)
    self.search_field.placeholderText = NSLocalizedString(@"Send by email or search...", nil);
  else
    self.search_field.placeholderText = NSLocalizedString(@"Send by email...", nil);
  self.search_field.toLabelTextColor = [UIColor blackColor];
  self.search_field.maxHeight = 112.0f;
  self.search_field.delegate = self;
  self.search_field.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [self fetchSwaggers];
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    [self fetchAddressBook];
    self.invite_button.enabled = YES;
  }
  else
  {
    self.invite_button.enabled = NO;
  }
  [self configureSearchField];
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userAvatarFetched:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  _managed_files_id = [[InfinitTemporaryFileManager sharedInstance] createManagedFiles];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
  {
    [self showAddressBookOverlay];
  }
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:_nav_bar_tap];
}

- (void)navBarTapped
{
  [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController.navigationBar.subviews[0] removeGestureRecognizer:_nav_bar_tap];
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - General

- (void)resetView
{
  [self.asset_urls removeAllObjects];
  [self.recipients removeAllObjects];
}

- (void)fetchSwaggers
{
  self.all_swaggers = [NSMutableArray array];
  for (InfinitUser* user in [[InfinitUserManager sharedInstance] swaggers])
  {
    if (user.ghost)
      continue;
    InfinitContact* contact = [[InfinitContact alloc] initWithInfinitUser:user];
    [self.all_swaggers addObject:contact];
  }
  self.swagger_results = [self.all_swaggers copy];
  [self.table_view reloadSections:[NSIndexSet indexSetWithIndex:0]
                 withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)fetchAddressBook
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    CFErrorRef* error = nil;
    ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, error);
    ABRecordRef source = ABAddressBookCopyDefaultSource(address_book);
    CFArrayRef contacts =
      ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(address_book,
                                                                source,
                                                                kABPersonSortByFirstName);
    self.all_contacts = [NSMutableArray array];

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
    self.contact_results = [self.all_contacts copy];
    [self.table_view reloadSections:[NSIndexSet indexSetWithIndex:1]
                   withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Overlays

- (void)showAddressBookOverlay
{
  if (self.contacts_overlay == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:@"InfinitAccessContactsView" bundle:nil];
    self.contacts_overlay = [[overlay_nib instantiateWithOwner:self options:nil] firstObject];
    [self.contacts_overlay.access_button addTarget:self
                                            action:@selector(accessAddressBook:)
                                  forControlEvents:UIControlEventTouchUpInside];
    [self.contacts_overlay.back_button addTarget:self
                                          action:@selector(cancelOverlayFromButton:)
                                forControlEvents:UIControlEventTouchUpInside];
  }
  [self showOverlayView:self.contacts_overlay];
}

- (void)showImportOverlay
{
  if (self.import_overlay == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:@"InfinitImportOverlayView" bundle:nil];
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
  self.contacts_overlay.message_label.text =
    NSLocalizedString(@"Tap \"OK\" so we can display\nyour contacts.", nil);
  self.contacts_overlay.access_button.hidden = YES;
  self.contacts_overlay.back_button.hidden = YES;
  CFErrorRef* error = nil;
  ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, error);
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                  message:@"Give me permission!"
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"OK", nil];
  alert.delegate = self;
  [alert show];
  if (ABAddressBookRequestAccessWithCompletion != NULL)
  {
    ABAddressBookRequestAccessWithCompletion(address_book, ^(bool granted, CFErrorRef error)
    {
      [self cancelOverlay:[sender superview]];
    });
  }
}

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  [self cancelOverlay:self.contacts_overlay];
  [self cancelOverlay:self.import_overlay];
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
  [[InfinitTemporaryFileManager sharedInstance] addAssetsLibraryURLList:self.asset_urls
                                                         toManagedFiles:_managed_files_id
                                                        performSelector:@selector(temporaryFileManagerCallback)
                                                               onObject:self];
}

- (void)temporaryFileManagerCallback
{
  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];
  NSMutableArray* actual_recipients = [NSMutableArray array];

  for (InfinitContact* contact in self.recipients)
  {
    if (contact.infinit_user != nil)
    {
      [actual_recipients addObject:contact.infinit_user];
    }
    else
    {
      [actual_recipients addObject:contact.emails[contact.selected_email_index]];
    }
  }
  NSArray* ids = [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                              toRecipients:actual_recipients
                                                               withMessage:@""];
  [[InfinitTemporaryFileManager sharedInstance] setTransactionIds:ids
                                                  forManagedFiles:_managed_files_id];
  [self.tabBarController performSelectorOnMainThread:@selector(showMainScreen)
                                          withObject:nil
                                       waitUntilDone:NO];
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
  return 2;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if (section == 0)
  {
    return self.swagger_results.count;
  }
  else
  {
    return (self.all_contacts.count > 0 ? self.contact_results.count : 1);
  }
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* res = nil;
  InfinitContact* contact = nil;
  if (indexPath.section == 0)
  {
    InfinitSendUserCell* cell = [tableView dequeueReusableCellWithIdentifier:_user_cell_id
                                                                forIndexPath:indexPath];
    contact = self.swagger_results[indexPath.row];
    cell.contact = contact;
    res = cell;
  }
  else
  {
    if (self.contact_results.count == 0)
    {
      InfinitSendImportCell* cell = [tableView dequeueReusableCellWithIdentifier:_import_cell_id
                                                                    forIndexPath:indexPath];
      res = cell;
    }
    else
    {
      InfinitSendContactCell* cell = [tableView dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
      contact = self.contact_results[indexPath.row];
      cell.contact = contact;
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
  return 35.0f;
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  UINib* header_nib = [UINib nibWithNibName:@"InfinitSendTableHeader" bundle:nil];
  InfinitSendTableHeader* header_view =
    [[header_nib instantiateWithOwner:self options:nil] firstObject];

  if (section == 0)
  {
    header_view.title.text = NSLocalizedString(@"My contacts on Infinit", nil);
  }
  else if (section == 1)
  {
    header_view.title.text = NSLocalizedString(@"Other contacts", nil);
  }
  return header_view;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == 0)
  {
    return 61.0f;
  }
  else
  {
    return (self.contact_results.count == 0 ? 349.0f : 61.0f);
  }
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.contact_results.count == 0 && indexPath.section == 1)
    return NO;
  return YES;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.recipients == nil)
    _recipients = [[NSMutableOrderedSet alloc] init];
  InfinitContact* contact = nil;
  if (indexPath.section == 0)
  {
    contact = self.swagger_results[indexPath.row];
  }
  else if (indexPath.section == 1)
  {
    contact = self.contact_results[indexPath.row];
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
}

- (void)actionSheetCancel:(UIActionSheet*)actionSheet
{
  InfinitContact* contact = self.recipients.lastObject;
  [self.recipients removeObject:contact];
  [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.contact_results
                                                                        indexOfObject:contact]
                                                             inSection:1]
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
                                                               inSection:1]
                                   animated:YES];
    [self.search_field reloadData];
  }
  else
  {
    NSUInteger email_index = buttonIndex - 1;
    InfinitContact* contact = self.recipients.lastObject;
    contact.selected_email_index = email_index;
  }
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
    constraint_final = - self.send_button.frame.size.height;
  }
  else
  {
    self.send_button.enabled = YES;
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
  if (self.asset_urls.count == 0 || self.recipients.count == 0)
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
}

- (void)tokenField:(VENTokenField*)tokenField
didDeleteTokenAtIndex:(NSUInteger)index
{
  InfinitContact* contact = self.recipients[index];
  if ([self.swagger_results containsObject:contact])
  {
    NSUInteger table_index = [self.swagger_results indexOfObject:contact];
    [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:table_index inSection:0]
                                   animated:YES];
  }
  else if ([self.contact_results containsObject:contact])
  {
    NSUInteger table_index = [self.contact_results indexOfObject:contact];
    [self.table_view deselectRowAtIndexPath:[NSIndexPath indexPathForRow:table_index inSection:1]
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
    [self addContactFromEmailAddress:_last_search];
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
  NSMutableIndexSet* sections = [NSMutableIndexSet indexSet];
  if (![self.swagger_results isEqualToArray:self.all_swaggers])
  {
    self.swagger_results = [self.all_swaggers copy];
    [sections addIndex:0];
  }
  if (![self.contact_results isEqualToArray:self.all_contacts])
  {
    self.contact_results = [self.all_contacts copy];
    [sections addIndex:1];
  }
  if (sections.count == 0)
    return;
  [self.table_view reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateSearchResultsWithSearchString:(NSString*)search_string
{
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
  if (![self.swagger_results isEqualToArray:swaggers_temp])
  {
    self.swagger_results = swaggers_temp;
    [sections addIndex:0];
  }
  if (![self.contact_results isEqualToArray:contacts_temp])
  {
    self.contact_results = contacts_temp;
    [sections addIndex:1];
  }
  if (sections.count > 0)
  {
    [self.table_view reloadSections:sections
                   withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - User Avatar

- (void)userAvatarFetched:(NSNotification*)notification
{
  NSNumber* updated_id = notification.userInfo[@"id"];
  NSUInteger row = 0;
  for (InfinitContact* contact in self.swagger_results)
  {
    if ([contact.infinit_user.id_ isEqualToNumber:updated_id])
    {
      NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:0];
      InfinitSendUserCell* cell = (InfinitSendUserCell*)[self.table_view cellForRowAtIndexPath:path];
      [cell performSelectorOnMainThread:@selector(updateAvatar) withObject:nil waitUntilDone:NO];
      return;
    }
    row++;
  }
}

@end
