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

  NSString* _import_cell_id;
  NSString* _user_cell_id;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _import_cell_id = @"send_import_cell";
    _user_cell_id = @"send_user_cell";
  }
  return self;
}

- (void)viewDidLoad
{
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
  [self.table_view reloadData];
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

- (void)fetchAddressBook
{
  CFErrorRef* error = nil;
  ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, error);
  __block BOOL access_granted = NO;

  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
  {
    if (ABAddressBookRequestAccessWithCompletion != NULL)
    {
      dispatch_semaphore_t sema = dispatch_semaphore_create(0);
      ABAddressBookRequestAccessWithCompletion(address_book, ^(bool granted, CFErrorRef error)
      {
        access_granted = granted;
        dispatch_semaphore_signal(sema);
      });
      dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
  }
  else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    access_granted = YES;
  }

  if (access_granted)
  {
    ABRecordRef source = ABAddressBookCopyDefaultSource(address_book);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(address_book, source, kABPersonSortByFirstName);
    
    _other_results = [NSMutableArray array];

    for (int i = 0; i < CFArrayGetCount(allPeople); i++)
    {
      ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
      if(person)
      {
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        NSMutableDictionary *userDict = [[NSMutableDictionary alloc] init];
        if (firstName && lastName)
        {
          [userDict setObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName] forKey:@"fullname"];
        }
        else if(firstName)
        {
          [userDict setObject:firstName forKey:@"fullname"];
        }
        else if(lastName)
        {
          [userDict setObject:lastName forKey:@"fullname"];
        }
        
        NSData  *imgData = (__bridge NSData *)ABPersonCopyImageData(person);
        UIImage *image = [UIImage imageWithData:imgData];
        if(image)
        {
          [userDict setObject:image forKey:@"avatar"];
        }
        
        [self.other_results addObject:userDict];
      }
    }
  }
}

#pragma mark Button Handling

- (IBAction)backButtonTapped:(id)sender
{
  [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:_managed_files_id];
  [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendButtonTapped:(id)sender
{
  [[InfinitTemporaryFileManager sharedInstance] addAssetsLibraryURLList:self.asset_urls
                                                         toManagedFiles:_managed_files_id
                                                        performSelector:@selector(temporaryFileManagerCallback)
                                                               onObject:self];
}

- (void)temporaryFileManagerCallback
{
  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];

  //Recipients are infinit users.
  NSArray* ids = [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                              toRecipients:nil
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
    return 1;
  }
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == 0)
  {
    InfinitSendUserCell* cell =
      (InfinitSendUserCell*)[tableView dequeueReusableCellWithIdentifier:_user_cell_id];
    cell.contact = self.swagger_results[indexPath.row];

    if ([self.table_view.indexPathsForSelectedRows containsObject:indexPath])
      cell.selected = YES;
    else
      cell.selected = NO;
     
    return cell;
  }
  else
  {
    InfinitSendImportCell* cell =
      (InfinitSendImportCell*)[tableView dequeueReusableCellWithIdentifier:_import_cell_id];
    return cell;
  }
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
    return 349.0f;
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


#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.recipients == nil)
    _recipients = [[NSMutableOrderedSet alloc] init];
  InfinitContact* contact =
    [(InfinitSendAbstractCell*)([self.table_view cellForRowAtIndexPath:indexPath]) contact];
  [_recipients addObject:contact];
}

- (void)tableView:(UITableView*)tableView
didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitContact* contact =
    [(InfinitSendAbstractCell*)([self.table_view cellForRowAtIndexPath:indexPath]) contact];
  [_recipients removeObject:contact];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [textField resignFirstResponder];
  return YES;
}

-(BOOL)prefersStatusBarHidden
{
  return YES;
}

- (IBAction)inviteBarButtonSelected:(id)sender
{
//  _inviteBarButtonView = [[UIView alloc] initWithFrame:  CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 44)];
//  _inviteBarButtonView.backgroundColor = [UIColor colorWithRed:81/255.0 green:81/255.0 blue:73/255.0 alpha:1];
//  
//  UIButton *importPhoneButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height - 267, self.view.frame.size.width - 54, 55)];
//  [importPhoneButton setTitle:@"IMPORT PHONE CONTACTS" forState:UIControlStateNormal];
//  [importPhoneButton setTitleColor:[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1]
//                          forState:UIControlStateNormal];
//  importPhoneButton.backgroundColor = [UIColor whiteColor];
//  importPhoneButton.layer.cornerRadius = 2.5f;
//  importPhoneButton.layer.borderWidth = 1.0f;
//  importPhoneButton.layer.borderColor = ([[[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
//  importPhoneButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
//  [_inviteBarButtonView addSubview:importPhoneButton];
//  
//  UIButton *findFacebookFriendsButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height - 199, self.view.frame.size.width - 54, 55)];
//  [findFacebookFriendsButton setTitle:@"FIND FACEBOOK FRIENDS" forState:UIControlStateNormal];
//  [findFacebookFriendsButton setTitleColor:[UIColor colorWithRed:42/255.0 green:108/255.0 blue:181/255.0 alpha:1]
//                                  forState:UIControlStateNormal];
//  [findFacebookFriendsButton setImage:[UIImage imageNamed:@"icon-facebook-blue"]
//                             forState:UIControlStateNormal];
//  findFacebookFriendsButton.backgroundColor = [UIColor whiteColor];
//  findFacebookFriendsButton.layer.cornerRadius = 2.5f;
//  findFacebookFriendsButton.layer.borderWidth = 1.0f;
//  findFacebookFriendsButton.layer.borderColor = ([[[UIColor colorWithRed:42/255.0 green:108/255.0 blue:181/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
//  findFacebookFriendsButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
//  [_inviteBarButtonView addSubview:findFacebookFriendsButton];
//  
//  UIButton *findPeopleButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height - 131, self.view.frame.size.width - 54, 55)];
//  [findPeopleButton setTitle:@"FIND PEOPLE ON INFINIT" forState:UIControlStateNormal];
//  [findPeopleButton setTitleColor:[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1]
//                         forState:UIControlStateNormal];
//  [findPeopleButton setImage:[UIImage imageNamed:@"icon-infinit-red"]
//                    forState:UIControlStateNormal];
//  findPeopleButton.backgroundColor = [UIColor whiteColor];
//  findPeopleButton.layer.cornerRadius = 2.5f;
//  findPeopleButton.layer.borderWidth = 1.0f;
//  findPeopleButton.layer.borderColor = ([[[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
//  findPeopleButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
//  [_inviteBarButtonView addSubview:findPeopleButton];
//  
//  UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height - 63, self.view.frame.size.width - 54, 55)];
//  [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
//  [cancelButton setTitleColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]
//                     forState:UIControlStateNormal];
//  cancelButton.layer.cornerRadius = 2.5f;
//  cancelButton.layer.borderWidth = 1.0f;
//  cancelButton.layer.borderColor = ([[UIColor whiteColor] CGColor]);
//  cancelButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
//  [cancelButton addTarget:self
//                   action:@selector(cancelInviteBarButtonView)
//         forControlEvents:UIControlEventTouchUpInside];
//  [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//  [_inviteBarButtonView addSubview:cancelButton];
//  
//  UITapGestureRecognizer *dismissInviteButtonView =
//  [[UITapGestureRecognizer alloc] initWithTarget:self
//                                          action:@selector(cancelInviteBarButtonView)];
//  [_inviteBarButtonView addGestureRecognizer:dismissInviteButtonView];
//  
//  
//  [[[[UIApplication sharedApplication] delegate] window] addSubview:_inviteBarButtonView];
}

- (void)cancelInviteBarButtonView
{
//  [_inviteBarButtonView removeFromSuperview];
}

- (void)showMyComputerView
{
//  _myself_view = [[UIView alloc] initWithFrame:  CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 44)];
//  
//  self.myself_view.backgroundColor = [UIColor colorWithRed:81/255.0 green:81/255.0 blue:73/255.0 alpha:1];
//  
//  UILabel *boldLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 142, 250, 70)];
//  boldLabel.text = @"You have Infinit installed on \n 2 other devices.";
//  boldLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:20];
//  boldLabel.numberOfLines = 2;
//  boldLabel.textAlignment = NSTextAlignmentCenter;
//  boldLabel.textColor = [UIColor whiteColor];
//  [self.myself_view addSubview:boldLabel];
//  
//  UILabel *lightLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 249, 250, 77)];
//  lightLabel.text = @"A notification will be sent to \n your 2 devices. Accept the files \n on the device you want!";
//  lightLabel.numberOfLines = 3;
//  lightLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
//  lightLabel.textAlignment = NSTextAlignmentCenter;
//  lightLabel.textColor = [UIColor whiteColor];
//  [self.myself_view addSubview:lightLabel];
//  
//  UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(27, 475, 266, 55)];
//  [cancelButton setTitle:@"GOT IT" forState:UIControlStateNormal];
//  [cancelButton setTitleColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]
//                     forState:UIControlStateNormal];
//  cancelButton.titleLabel.textColor = [UIColor whiteColor];
//  cancelButton.layer.cornerRadius = 2.5f;
//  cancelButton.layer.borderWidth = 1.0f;
//  cancelButton.layer.borderColor = ([[UIColor whiteColor] CGColor]);
//  cancelButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
//  [cancelButton addTarget:self
//                   action:@selector(cancelMyComputerView)
//         forControlEvents:UIControlEventTouchUpInside];
//  [self.myself_view addSubview:cancelButton];
//  
//  
//  [[[[UIApplication sharedApplication] delegate] window] addSubview:self.myself_view];
}

- (void)cancelMyComputerView
{
//  [self.myself_view removeFromSuperview];
}

@end
