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
#import "InfinitContactsTableHeader.h"
#import "InfinitContactImportCell.h"
#import "InfinitImportOverlayView.h"

#import <Gap/InfinitUserManager.h>

@import AddressBook;

@interface InfinitContactsViewController () <UISearchBarDelegate,
                                             UITableViewDataSource,
                                             UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (nonatomic, strong) InfinitAccessContactsView* contacts_overlay;
@property (nonatomic, strong) InfinitImportOverlayView* import_overlay;

@property (nonatomic, strong) NSMutableArray* all_contacts;
@property (nonatomic, strong) NSArray* contact_results;
@property (nonatomic, strong) NSMutableArray* all_swaggers;
@property (nonatomic, strong) NSArray* swagger_results;

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

- (void)viewDidLoad
{
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
}

- (void)viewWillAppear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userAvatarFetched:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  if (_should_refresh)
  {
    [self fetchSwaggers];
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
      [self fetchAddressBook];
//      self.invite_button.enabled = YES;
    }
    else
    {
//      
    }
  }
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  _should_refresh = YES;
  [super viewDidAppear:animated];
  if (self.table_view.indexPathForSelectedRow != nil)
  {
    [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow
                                   animated:animated];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

- (void)fetchSwaggers
{
  self.all_swaggers = [NSMutableArray array];
  for (InfinitUser* user in [InfinitUserManager sharedInstance].swaggers)
  {
    if (user.ghost)
      continue;
    InfinitContact* contact = [[InfinitContact alloc] initWithInfinitUser:user];
    [self.all_swaggers addObject:contact];
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
    [self.table_view reloadData];
  }
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
    [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
  }
  else
  {
    [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
  }
}

#pragma mark - Search Bar Delegate

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

- (void)searchBar:(UISearchBar*)searchBar
    textDidChange:(NSString*)searchText
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(updateSearchResultsWithSearchString:)
                                             object:_last_search];
  _last_search = searchText;
  if (searchText.length == 0)
  {
    [self reloadSearchResults];
    return;
  }
  [self performSelector:@selector(updateSearchResultsWithSearchString:)
             withObject:searchText.lowercaseString
             afterDelay:0.3f];
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
//  else if ([self noResults])
//  {
//    [self.table_view reloadData];
//  }
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
  [searchBar resignFirstResponder];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return 2;
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  UINib* header_nib = [UINib nibWithNibName:@"InfinitContactsTableHeader" bundle:nil];
  InfinitContactsTableHeader* header_view =
    [[header_nib instantiateWithOwner:self options:nil] firstObject];

  if (section == 0)
  {
    header_view.title.text = NSLocalizedString(@"My contacts on Infinit", nil);
  }
  else if (section == 1)
  {
    if (self.all_contacts.count > 0)
      header_view.title.text = NSLocalizedString(@"Other contacts", nil);
    else
      header_view.title.text = @"";
  }
  return header_view;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if (section == 0)
    return self.swagger_results.count;
  else
    return ([self askedForAddressBookAccess] ? self.contact_results.count : 1);
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* res;
  if (indexPath.section == 0)
  {
    InfinitContactCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_contact_cell_id
                                                                     forIndexPath:indexPath];
    cell.contact = self.swagger_results[indexPath.row];
    res = cell;
  }
  else
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
      res = cell;
    }
  }
  return res;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == 0)
  {
    return 52.0f;
  }
  else
  {
    return ([self askedForAddressBookAccess] ? 52.0f : 349.0f);
  }
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
      NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:0];
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
      view_controller.contact = self.swagger_results[index.row];
    else
      view_controller.contact = self.contact_results[index.row];
    [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow
                                   animated:YES];
    _should_refresh = NO;
  }
}

@end
