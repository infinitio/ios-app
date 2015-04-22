//
//  InfinitContactsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactsViewController.h"

#import "InfinitAccessContactsView.h"
#import "InfinitColor.h"
#import "InfinitContactCell.h"
#import "InfinitContactViewController.h"
#import "InfinitContactImportCell.h"
#import "InfinitHostDevice.h"
#import "InfinitImportOverlayView.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitUserManager.h>

@import AddressBook;

@interface InfinitContactsViewController () <UISearchBarDelegate,
                                             UITableViewDataSource,
                                             UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (nonatomic, strong) InfinitAccessContactsView* contacts_overlay;
@property (nonatomic, strong) InfinitImportOverlayView* import_overlay;

@property (atomic, strong) InfinitContact* me_contact;
@property (nonatomic) BOOL me_match;
@property (atomic, strong) NSMutableArray* all_swaggers;
@property (atomic, strong) NSMutableArray* swagger_results;
@property (atomic, strong) NSMutableArray* all_contacts;
@property (atomic, strong) NSMutableArray* contact_results;

@property (atomic) BOOL preloading_contacts;

@end

@implementation InfinitContactsViewController
{
@private
  NSString* _contact_cell_id;
  NSString* _import_cell_id;

  NSString* _last_search;

  BOOL _should_refresh;
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _contact_cell_id = @"contacts_contact_cell";
    _import_cell_id = @"contact_import_cell";
    _should_refresh = YES;
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
  _me_match = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (_should_refresh && self.current_status)
  {
    [self refreshContents];
  }
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userAvatarFetched:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 2.0f) animated:NO];
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
  _should_refresh = YES;
  [super viewDidAppear:animated];
  if (self.table_view.indexPathForSelectedRow != nil)
  {
    NSIndexPath* index = self.table_view.indexPathForSelectedRow;
    [self.table_view deselectRowAtIndexPath:index animated:animated];
    [self fetchSwaggers];
    self.search_bar.text = @"";
    [self reloadSearchResults];
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
  for (InfinitUser* user in [manager alphabetical_swaggers])
  {
    if (!user.ghost && !user.deleted)
      [self.all_swaggers addObject:[[InfinitContact alloc] initWithInfinitUser:user]];
  }
  self.swagger_results = [self.all_swaggers mutableCopy];
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
          if (contact != nil && (contact.emails.count > 0 ||
                                 ([InfinitHostDevice canSendSMS] && contact.phone_numbers.count > 0)))
          {
            [self.all_contacts addObject:contact];
          }
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
                        waitUntilDone:YES];
  }
  self.preloading_contacts = NO;
}

- (void)reloadTableSections:(NSIndexSet*)set
{
  [self.table_view reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
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
  view.frame = [UIScreen mainScreen].bounds;
  [[UIApplication sharedApplication].keyWindow addSubview:view];
  [UIView animateWithDuration:0.5f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     [[UIApplication sharedApplication] setStatusBarHidden:YES
                                             withAnimation:UIStatusBarAnimationFade];
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
    NSLocalizedString(@"Tap 'OK' so we can display\nyour contacts.", nil);
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
  [[UIApplication sharedApplication] setStatusBarHidden:NO
                                          withAnimation:UIStatusBarAnimationFade];
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
    [sections addIndex:0];
  }
  if (![self.swagger_results isEqualToArray:self.all_swaggers])
  {
    self.swagger_results = [self.all_swaggers mutableCopy];
    [sections addIndex:1];
  }
  if (![self.contact_results isEqualToArray:self.all_contacts] && [self gotAccessToAddressBook])
  {
    self.contact_results = [self.all_contacts mutableCopy];
    [sections addIndex:2];
  }
  if (sections.count > 0)
    [self.table_view reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)searchBar:(UISearchBar*)searchBar
    textDidChange:(NSString*)searchText
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(updateSearchResultsWithSearchString:)
                                             object:_last_search];
  if (searchText.length == 0)
  {
    [self reloadSearchResults];
    return;
  }
  _last_search = searchText;
  [self performSelector:@selector(updateSearchResultsWithSearchString:)
             withObject:searchText
             afterDelay:0.25f];
}

- (void)updateSearchResultsWithSearchString:(NSString*)search_string
{
  @synchronized(self)
  {
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
    [sections addIndex:0];
    if (![self.swagger_results isEqualToArray:swaggers_temp])
    {
      self.swagger_results = swaggers_temp;
      [sections addIndex:1];
    }
    if (![self.contact_results isEqualToArray:contacts_temp] && [self gotAccessToAddressBook])
    {
      self.contact_results = contacts_temp;
      [sections addIndex:2];
    }
    if (sections.count > 0)
    {
      [self.table_view reloadSections:sections
                     withRowAnimation:UITableViewRowAnimationAutomatic];
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
  UITableViewCell* res;
  if (indexPath.section == 0)
  {
    InfinitContactCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
    cell.contact = self.me_contact;
    cell.icon_view.hidden = NO;
    cell.letter_label.hidden = YES;
    res = cell;
  }
  else if (indexPath.section == 1)
  {
    InfinitContactCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
    cell.contact = self.swagger_results[indexPath.row];
    cell.icon_view.hidden = !cell.contact.infinit_user.favorite;
    cell.letter_label.hidden = YES;
    res = cell;
  }
  else if (indexPath.section == 2)
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
  if (indexPath.section == 2 && ![self askedForAddressBookAccess])
  {
    return 349.0f;
  }
  else
  {
    return 62.0f;
  }
}

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (![self askedForAddressBookAccess] && indexPath.section == 2)
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

#pragma mark - User Avatar

- (void)userAvatarFetched:(NSNotification*)notification
{
  NSNumber* updated_id = notification.userInfo[@"id"];
  NSUInteger row = 0;
  for (InfinitContact* contact in self.swagger_results)
  {
    if ([contact.infinit_user.id_ isEqualToNumber:updated_id])
    {
      NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:1];
      InfinitContactCell* cell = (InfinitContactCell*)[self.table_view cellForRowAtIndexPath:path];
      [cell performSelectorOnMainThread:@selector(updateAvatar) withObject:nil waitUntilDone:NO];
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
    if (index.section == 0)
      view_controller.contact = self.me_contact;
    else if (index.section == 1)
      view_controller.contact = self.swagger_results[index.row];
    else
      view_controller.contact = self.contact_results[index.row];
    _should_refresh = NO;
  }
}

#pragma mark - Status Changed

- (void)statusChangedTo:(BOOL)status
{
  if (status)
    [self refreshContents];
  [super statusChangedTo:status];
}

@end
