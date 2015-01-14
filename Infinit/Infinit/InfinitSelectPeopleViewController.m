//
//  InfinitSelectPeopleViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSelectPeopleViewController.h"

#import <AddressBook/AddressBook.h>

#import "InfinitContact.h"
#import "InfinitAccessContactsView.h"
#import "InfinitImportOverlayView.h"
#import "InfinitSendUserCell.h"
#import "InfinitSendImportCell.h"
#import "InfinitSendContactCell.h"
#import "InfinitSendContactsHeaderView.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/InfinitUtilities.h>

@interface InfinitSelectPeopleViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* invite_button;
@property (nonatomic, weak) IBOutlet UITextField* search_field;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UIButton* send_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_constraint;

@property (nonatomic, strong) InfinitAccessContactsView* contacts_overlay;
@property (nonatomic, strong) InfinitImportOverlayView* import_overlay;
@property (nonatomic, strong) NSMutableArray* other_results;
@property (nonatomic, strong) NSMutableOrderedSet* recipients;
@property (nonatomic, strong) NSMutableArray* swagger_results;

@end

@implementation InfinitSelectPeopleViewController
{
@private
  NSString* _managed_files_id;

  NSString* _contact_cell_id;
  NSString* _import_cell_id;
  NSString* _user_cell_id;
}

#pragma mark Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _contact_cell_id = @"send_contact_cell";
    _import_cell_id = @"send_import_cell";
    _user_cell_id = @"send_user_cell";
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
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  [self.invite_button setTitleTextAttributes:nav_bar_attrs forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  _managed_files_id = [[InfinitTemporaryFileManager sharedInstance] createManagedFiles];
  [self fetchSwaggers];
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    [self fetchAddressBook];
  }
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
  {
    [self showAddressBookOverlay];
  }
}

- (void)fetchSwaggers
{
  self.swagger_results = [NSMutableArray array];
  for (InfinitUser* user in [[InfinitUserManager sharedInstance] swaggers])
  {
    InfinitContact* contact = [[InfinitContact alloc] initWithInfinitUser:user];
    [self.swagger_results addObject:contact];
  }
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
    _other_results = [NSMutableArray array];

    for (int i = 0; i < CFArrayGetCount(contacts); i++)
    {
      ABRecordRef person = CFArrayGetValueAtIndex(contacts, i);
      if (person)
      {
        InfinitContact* contact = [[InfinitContact alloc] initWithABRecord:person];
        if (contact != nil)
          [self.other_results addObject:contact];
      }
    }
    [self.table_view reloadSections:[NSIndexSet indexSetWithIndex:1]
                   withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark Overlays

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
//    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(address_book, ^(bool granted, CFErrorRef error)
    {
//      dispatch_semaphore_signal(sema);
      [self cancelOverlay:[sender superview]];
    });
//    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
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

#pragma mark Button Handling

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

- (IBAction)inviteBarButtonTapped:(id)sender
{
  
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
      NSLog(@"xxx only handle users for now");
    }
  }
  NSArray* ids = [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                              toRecipients:actual_recipients
                                                               withMessage:@"from iOS"];
  [[InfinitTemporaryFileManager sharedInstance] setTransactionIds:ids
                                                  forManagedFiles:_managed_files_id];
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
    return (self.other_results.count > 0 ? self.other_results.count : 1);
  }
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* res = nil;
  if (indexPath.section == 0)
  {
    InfinitSendUserCell* cell =
      (InfinitSendUserCell*)[tableView dequeueReusableCellWithIdentifier:_user_cell_id];
    cell.contact = self.swagger_results[indexPath.row];
    res = cell;
  }
  else
  {
    if (self.other_results.count == 0)
    {
      InfinitSendImportCell* cell =
        (InfinitSendImportCell*)[tableView dequeueReusableCellWithIdentifier:_import_cell_id];
      res = cell;
    }
    else
    {
      InfinitSendContactCell* cell =
        (InfinitSendContactCell*)[tableView dequeueReusableCellWithIdentifier:_contact_cell_id];
      cell.contact = self.other_results[indexPath.row];
      res = cell;
    }
  }

  if ([self.table_view.indexPathsForSelectedRows containsObject:indexPath])
    res.selected = YES;
  else
    res.selected = NO;

  return res;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  return 25.0f;
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
    return (self.other_results.count == 0 ? 349.0f : 61.0f);
  }
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  UINib* header_nib = [UINib nibWithNibName:@"InfinitSendContactsHeaderView" bundle:nil];
  InfinitSendContactsHeaderView* header =
    [[header_nib instantiateWithOwner:self options:nil] firstObject];
  switch (section)
  {
    case 0:
      header.title.text = NSLocalizedString(@"My contacts on Infinit", nil);
      break;
    case 1:
      header.title.text = NSLocalizedString(@"Other contacts", nil);
      break;

    default:
      break;
  }
  return header;
}


#pragma mark Table View Delegate

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.other_results.count == 0 && indexPath.section == 1)
    return NO;
  return YES;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.recipients == nil)
    _recipients = [[NSMutableOrderedSet alloc] init];
  InfinitContact* contact =
    [(InfinitSendAbstractCell*)([self.table_view cellForRowAtIndexPath:indexPath]) contact];
  [_recipients addObject:contact];
  [self updateSendButton];
}

- (void)tableView:(UITableView*)tableView
didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitContact* contact =
    [(InfinitSendAbstractCell*)([self.table_view cellForRowAtIndexPath:indexPath]) contact];
  [_recipients removeObject:contact];
  [self updateSendButton];
}

#pragma mark Text Input Handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [textField resignFirstResponder];
  return YES;
}

#pragma mark Helpers

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

@end
