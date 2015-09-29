//
//  InfinitContactsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactsViewController.h"

#import "InfinitAccessContactsView.h"
#import "InfinitConstants.h"
#import "InfinitContactCell.h"
#import "InfinitContactManager.h"
#import "InfinitContactViewController.h"
#import "InfinitContactImportCell.h"
#import "InfinitFacebookManager.h"
#import "InfinitHostDevice.h"
#import "InfinitImportOverlayView.h"
#import "InfinitMetricsManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <Gap/InfinitExternalAccountsManager.h>
#import <Gap/InfinitColor.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

@import AddressBook;

typedef NS_ENUM(NSUInteger, InfinitContactsSection)
{
  InfinitContactsSectionSelf      = 0,
  InfinitContactsSectionSwaggers  = 1,
  InfinitContactsSectionContacts  = 2,
};

@interface InfinitContactsViewController () <UISearchBarDelegate,
                                             UITableViewDataSource,
                                             UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* add_contacts_button;
@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (nonatomic, strong) InfinitAccessContactsView* contacts_overlay;
@property (nonatomic, strong) InfinitImportOverlayView* import_overlay;

@property (atomic, strong) InfinitContactUser* me_contact;
@property (nonatomic) BOOL me_match;
@property (atomic, strong) NSMutableArray* all_swaggers;
@property (atomic, strong) NSMutableArray* swagger_results;
@property (atomic, strong) NSMutableArray* all_contacts;
@property (atomic, strong) NSMutableArray* contact_results;
@property (atomic) NSString* last_search;

@property (atomic) BOOL preloading_contacts;
@property (atomic) BOOL should_refresh;

@end

static NSString* _contact_cell_id = @"contacts_contact_cell";
static NSString* _import_cell_id = @"contact_import_cell";

@implementation InfinitContactsViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    self.should_refresh = YES;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  CGRect footer_rect = CGRectMake(0.0f, 0.0f, self.table_view.bounds.size.width, 60.0f);
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:footer_rect];
  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitContactCell.class) bundle:nil];
  [self.table_view registerNib:cell_nib forCellReuseIdentifier:_contact_cell_id];
  UINib* import_cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitContactImportCell.class)
                                          bundle:nil];
  [self.table_view registerNib:import_cell_nib forCellReuseIdentifier:_import_cell_id];
  UIGraphicsBeginImageContextWithOptions(self.search_bar.bounds.size, NO, 0.0f);
  [[InfinitColor colorWithGray:243] set];
  CGContextFillRect(UIGraphicsGetCurrentContext(), self.search_bar.bounds);
  UIImage* search_bar_bg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.search_bar.backgroundImage = search_bar_bg;
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.table_view.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.table_view.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
  self.search_bar.tintColor = [InfinitColor colorWithGray:46];
  _me_match = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (self.should_refresh && self.current_status)
  {
    [self refreshContents];
    [self.table_view setContentOffset:CGPointZero animated:NO];
  }
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
           self.add_contacts_button && ![toolbar_items containsObject:self.add_contacts_button])
  {
    NSMutableArray* res = [toolbar_items mutableCopy];
    [res addObject:self.add_contacts_button];
    self.navigationItem.rightBarButtonItems = res;
  }
}

- (void)refreshContents
{
  _me_match = YES;
  [self fetchSwaggers];
  self.search_bar.text = @"";
  [self reloadSearchResults];
}

- (void)viewDidAppear:(BOOL)animated
{
  self.should_refresh = YES;
  [super viewDidAppear:animated];
  if (self.table_view.indexPathForSelectedRow != nil)
  {
    NSIndexPath* index = self.table_view.indexPathForSelectedRow;
    [self.table_view deselectRowAtIndexPath:index animated:animated];
    if (index.section == InfinitContactsSectionSwaggers) // User could've been (un)favorited.
    {
      [self.table_view reloadRowsAtIndexPaths:@[index]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
    }
  }
  else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    self.preloading_contacts = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
      [self fetchAddressBook];
    });
  }
  else
  {
    self.preloading_contacts = NO;
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
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
  for (InfinitUser* user in [manager alphabetical_swaggers])
  {
    if (!user.deleted)
      [res addObject:[InfinitContactUser contactWithInfinitUser:user]];
  }
  return res;
}

- (void)fetchSwaggers
{
  InfinitUserManager* manager = [InfinitUserManager sharedInstance];
  self.me_contact = [InfinitContactUser contactWithInfinitUser:[manager me]];
  self.all_swaggers = [self swaggers];
  self.swagger_results = [self.all_swaggers mutableCopy];
  [self.table_view reloadData];
}

- (void)fetchAddressBook
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    self.all_contacts = [[[InfinitContactManager sharedInstance] allContacts] mutableCopy];
    self.contact_results = [self.all_contacts mutableCopy];
    dispatch_sync(dispatch_get_main_queue(), ^
    {
      [self reloadTableSections:[NSIndexSet indexSetWithIndex:InfinitContactsSectionContacts]];
    });
  }
  self.preloading_contacts = NO;
}

- (void)reloadTableSections:(NSIndexSet*)set
{
  NSRange section_range = NSMakeRange(0, self.table_view.numberOfSections);
  if ([set containsIndexes:[NSIndexSet indexSetWithIndexesInRange:section_range]])
    [self.table_view reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
  else
    [self.table_view reloadData];
}

#pragma mark - Overlays

- (void)showAddressBookOverlay
{
  UINib* overlay_nib = [UINib nibWithNibName:@"InfinitAccessContactsView" bundle:nil];
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

- (void)showOverlayView:(UIView*)view
{
  self.view.userInteractionEnabled = NO;
  view.alpha = 0.0f;
  view.frame = [UIScreen mainScreen].bounds;
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
  __weak InfinitContactsViewController* weak_self = self;
  ABAddressBookRequestAccessWithCompletion(address_book, ^(bool granted, CFErrorRef error)
   {
     if (granted)
     {
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
       {
         [weak_self fetchAddressBook];
       });
       [InfinitMetricsManager sendMetric:InfinitUIEventAccessContacts method:InfinitUIMethodYes];
     }
     else
     {
       [InfinitMetricsManager sendMetric:InfinitUIEventAccessContacts method:InfinitUIMethodNo];
     }
     dispatch_async(dispatch_get_main_queue(), ^
     {
       [weak_self cancelOverlayFromButton:sender];
     });
   });
}

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
  __weak InfinitContactsViewController* weak_self = self;
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  [manager.login_manager logInWithReadPermissions:kInfinitFacebookReadPermissions
                               fromViewController:self
                                          handler:^(FBSDKLoginManagerLoginResult* result,
                                                    NSError* error)
  {
    InfinitContactsViewController* strong_self = weak_self;
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
      InfinitContactsViewController* strong_self = weak_self;
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

#pragma mark - General

- (void)tabIconTap
{
  if (![self.navigationController.visibleViewController isEqual:self])
  {
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 2.0f) animated:NO];
  }
  else
  {
    [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 2.0f) animated:YES];
  }
}

#pragma mark - Search Bar Delegate

- (void)reloadSearchResults
{
  NSMutableIndexSet* sections = [NSMutableIndexSet indexSet];
  if (!_me_match)
  {
    _me_match = YES;
    [sections addIndex:InfinitContactsSectionSelf];
  }
  if (![self.swagger_results isEqualToArray:self.all_swaggers])
  {
    self.swagger_results = [self.all_swaggers mutableCopy];
    [sections addIndex:InfinitContactsSectionSwaggers];
  }
  if (![self.contact_results isEqualToArray:self.all_contacts] && [self gotAccessToAddressBook])
  {
    self.contact_results = [self.all_contacts mutableCopy];
    [sections addIndex:InfinitContactsSectionContacts];
  }
  if (sections.count > 0)
    [self.table_view reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)searchBar:(UISearchBar*)searchBar
    textDidChange:(NSString*)searchText
{
  if (searchText.length == 0)
  {
    [self reloadSearchResults];
    return;
  }
  self.last_search = searchText;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(250 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self updateSearchResultsWithSearchString:searchText];
  });
}

- (void)updateSearchResultsWithSearchString:(NSString*)search_string
{
  @synchronized(self)
  {
    if (![self.last_search isEqual:search_string])
      return;
    if (self.preloading_contacts)
    {
      [self performSelector:@selector(updateSearchResultsWithSearchString:)
                 withObject:search_string 
                 afterDelay:0.3f];
      return;
    }
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
    [sections addIndex:InfinitContactsSectionSelf];
    if (![self.swagger_results isEqualToArray:swaggers_temp])
    {
      self.swagger_results = swaggers_temp;
      [sections addIndex:InfinitContactsSectionSwaggers];
    }
    if (![self.contact_results isEqualToArray:contacts_temp] && [self gotAccessToAddressBook])
    {
      self.contact_results = contacts_temp;
      [sections addIndex:InfinitContactsSectionContacts];
    }
    if (sections.count > 0)
    {
      [self reloadTableSections:sections];
    }
  }
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
  [searchBar resignFirstResponder];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
      ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted)
    return 2;
  return 3;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case InfinitContactsSectionSelf:
      if (self.me_match)
        break;
      else
        return 0.0f;
    case InfinitContactsSectionSwaggers:
      if (self.swagger_results.count > 0)
        break;
      else
        return 0.0f;
    case InfinitContactsSectionContacts:
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
  header.backgroundColor = [UIColor whiteColor];
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

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case InfinitContactsSectionSelf:
      return self.me_match ? 1 : 0;
    case InfinitContactsSectionSwaggers:
      return self.swagger_results.count;
    case InfinitContactsSectionContacts:
      return ([self askedForAddressBookAccess] ? self.contact_results.count : 1);

    default:
      return 0;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* res;
  if (indexPath.section == InfinitContactsSectionSelf)
  {
    InfinitContactCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
    cell.contact = self.me_contact;
    cell.icon_view.hidden = NO;
    cell.letter_label.hidden = YES;
    res = cell;
  }
  else if (indexPath.section == InfinitContactsSectionSwaggers)
  {
    InfinitContactCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
    InfinitContactUser* contact = self.swagger_results[indexPath.row];
    cell.contact = contact;
    cell.icon_view.hidden = !contact.infinit_user.favorite;
    cell.letter_label.hidden = YES;
    res = cell;
  }
  else if (indexPath.section == InfinitContactsSectionContacts)
  {
    if (self.all_contacts.count == 0)
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
      InfinitContactCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                       forIndexPath:indexPath];
      cell.contact = self.contact_results[indexPath.row];
      cell.icon_view.hidden = YES;
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
  if ([tableView.indexPathsForSelectedRows containsObject:indexPath])
    res.selected = YES;
  return res;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == InfinitContactsSectionContacts && ![self askedForAddressBookAccess])
    return 349.0f;
  else
    return 62.0f;
}

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (![self askedForAddressBookAccess] && indexPath.section == InfinitContactsSectionContacts)
    return NO;
  return YES;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [self performSegueWithIdentifier:@"contacts_to_contact_segue" sender:self];
}

#pragma mark - Button Handling

- (void)importPhoneContactsTapped:(id)sender
{
  [self showAddressBookOverlay];
}

- (IBAction)addContactsTapped:(id)sender
{
  [self showImportOverlay];
}

#pragma mark - User Added

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
    [NSIndexPath indexPathForRow:0 inSection:InfinitContactsSectionSwaggers];
  [self.table_view insertRowsAtIndexPaths:@[index]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
  [self.table_view endUpdates];
}

#pragma mark - User Avatar

- (void)userAvatarFetched:(NSNotification*)notification
{
  NSNumber* updated_id = notification.userInfo[@"id"];
  NSUInteger row = 0;
  for (InfinitContactUser* contact in self.swagger_results)
  {
    if ([contact.infinit_user.id_ isEqualToNumber:updated_id])
    {
      NSIndexPath* path = [NSIndexPath indexPathForRow:row
                                             inSection:InfinitContactsSectionSwaggers];
      InfinitContactCell* cell = (InfinitContactCell*)[self.table_view cellForRowAtIndexPath:path];
      dispatch_async(dispatch_get_main_queue(), ^
      {
        [cell updateAvatar];
      });
      return;
    }
    row++;
  }
}

#pragma mark - Helpers

- (BOOL)noResults
{
  return (self.swagger_results.count == 0 && self.contact_results.count == 0);
}

- (BOOL)gotAccessToAddressBook
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    return YES;
  return NO;
}

- (BOOL)askedForAddressBookAccess
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    return NO;
  return YES;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.destinationViewController isKindOfClass:InfinitContactViewController.class])
  {
    InfinitContactViewController* view_controller =
      (InfinitContactViewController*)segue.destinationViewController;
    NSIndexPath* index = self.table_view.indexPathForSelectedRow;
    if (index.section == InfinitContactsSectionSelf)
      view_controller.contact = self.me_contact;
    else if (index.section == InfinitContactsSectionSwaggers)
      view_controller.contact = self.swagger_results[index.row];
    else if (index.section == InfinitContactsSectionContacts)
      view_controller.contact = self.contact_results[index.row];
    self.should_refresh = NO;
  }
}

- (IBAction)unwindToContactsViewController:(UIStoryboardSegue*)segue
{}

#pragma mark - Status Changed

- (void)statusChangedTo:(BOOL)status
{
  if (status)
    [self refreshContents];
  [super statusChangedTo:status];
}

@end
