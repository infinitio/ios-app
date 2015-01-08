//
//  InfinitContactsTableViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/21/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitContactsTableViewController.h"

#import "ContactCell.h"
#import "ImportContactsCell.h"
#import "ContactOtherCell.h"

#import <AddressBook/AddressBook.h>

#import "CGLContact.h"
#import "CGLAlphabetizer.h"

@interface InfinitContactsTableViewController ()

@property (strong, nonatomic) NSMutableArray* people;
@property (strong, nonatomic) NSArray* alphabet_indexes;
@property (strong, nonatomic) NSDictionary* sorted_contacts;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* invite_bar_button;
@property (strong, nonatomic) UIView* invite_bar_button_view;
@property int selected_row;

@end

@implementation InfinitContactsTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  //No row has been selected yet.  Makes sure no cells are shown in the selected state.
  self.selected_row = -1;
  
  //Setting Font
  NSDictionary* attributes =
    @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:18]};
  [self.invite_bar_button setTitleTextAttributes:attributes
                                  forState:UIControlStateNormal];

  [self fetchContacts];
}

-(void)fetchContacts
{
  CFErrorRef *error =
    nil;
  ABAddressBookRef addressBook =
    ABAddressBookCreateWithOptions(NULL, error);
  
  __block BOOL accessGranted =
    NO;
  if (ABAddressBookRequestAccessWithCompletion != NULL)
  { // we're on iOS 6 or later.
    dispatch_semaphore_t sema =
      dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
    {
      accessGranted =
        granted;
      dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
  }
  else
  { // we're on iOS 5 or older
    accessGranted = YES;
  }
  
  if (accessGranted)
  {
    ABAddressBookRef addressBook =
      ABAddressBookCreateWithOptions(NULL, error);
    ABRecordRef source =
      ABAddressBookCopyDefaultSource(addressBook);
    CFArrayRef all_people =
      ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
    
    self.people =
      [[NSMutableArray alloc] init];
    
    for (int i = 0; i < CFArrayGetCount(all_people); i++)
    {
      ABRecordRef person =
        CFArrayGetValueAtIndex(all_people, i);
      if(person)
      {
        NSString* first_name =
          (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString* last_name =
          (__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        CGLContact* contact =
          [[CGLContact alloc] init];

        if(first_name && last_name)
        {
          [contact setFirstName:first_name];
          [contact setLastName:last_name];
        }
        else if(first_name)
        {
          [contact setFirstName:first_name];
        }
        else if(last_name)
        {
          [contact setLastName:last_name];
        }
        /*  Getting image from address book.
        NSData  *imgData = (__bridge NSData *)ABPersonCopyImageData(person);
        UIImage *image = [UIImage imageWithData:imgData];
        if(image)
        {
          [userDict setObject:image forKey:@"avatar"];
        }
         */
        
        [self.people addObject:contact];
      }
    }
    //Now sort the people array.
    self.sorted_contacts =
      [CGLAlphabetizer alphabetizedDictionaryFromObjects:self.people usingKeyPath:@"firstName"];
    self.alphabet_indexes =
      [CGLAlphabetizer indexTitlesFromAlphabetizedDictionary:self.sorted_contacts];
    [self.tableView reloadData];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if(section == 0)
  {
    return 1;
  }
  else
  {
    return 10;
  }
  
  /* Phone book logic.  How many contacts in each letter of the alphabet.
  NSArray *array = self.sorted_contacts[self.alphabet_indexes[section]];
  if(array)
  {
    return array.count;
  } 
  else
  {
    return 0;
  }
   */
}

- (UITableViewCell*)tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if(indexPath.section == 0)
  {
    ContactCell* cell =
      (ContactCell*)[tableView dequeueReusableCellWithIdentifier:@"contactCell"
                                                    forIndexPath:indexPath];
    cell.name_label.text = @"My Computer";
    
    /*  Gap will be supplying contacts, so this snipper isn't useful yet.
     NSString* name = 
      [self.people[indexPath.row] objectForKey:@"fullname"];
     if(name)
     {
        cell.nameLabel.text = name;
     }
     
     UIImage* image = 
      [self.people[indexPath.row] objectForKey:@"avatar"];
     if(image)
     {
        cell.avatarImageView.image = image;
     }
     */
    return cell;
  }
  else
  {
    ContactOtherCell* cell =
      (ContactOtherCell*)[tableView dequeueReusableCellWithIdentifier:@"otherContactCell"
                                                         forIndexPath:indexPath];
    cell.name_label.text = @"Koze";
    cell.info_label.text = @"koze@gmail.com";
    
    
    return cell;
    
    /* IF we don't have anybody, show an import cell.
    ImportContactsCell* cell =
     (ImportContactsCell*)[tableView dequeueReusableCellWithIdentifier:@"importCell"
                                                          forIndexPath:indexPath];
     [cell.importPhoneContactsButton addTarget:self
                                        action:@selector(importPhoneContacts)
                              forControlEvents:UIControlEventTouchUpInside];
     [cell.importFacebookButton addTarget:self
                                   action:@selector(importFacebookContacts)
                         forControlEvents:UIControlEventTouchUpInside];
     [cell.find_people_button addTarget:self
                               action:@selector(find_people_button)
                     forControlEvents:UIControlEventTouchUpInside];
    return cell;
     */
  }
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  
  if (section == 1)
  {
    CGFloat height =
      25.0;
    return height;
  }
  else
  {
    CGFloat height =
      25.0;
    return height;
  }
  
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == 0)
  {
    if(indexPath.row == self.selected_row)
    {
      return 95;
    }
    else
    {
      return 50;
    }
  }
  else
  {
    return 55;
    //IF its the invite one make it 349.  Add this logic.
  }
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  if (section == 1)
  {
    UIView* header_view =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 25)];
    header_view.backgroundColor = [UIColor colorWithRed:243/255.0 green:243/255.0 blue:243/255.0 alpha:1];
    
    UILabel* other_contacts_label =
      [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 200, 25)];
    other_contacts_label.text = @"Other contacts";
    other_contacts_label.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:10.5];
    other_contacts_label.textColor = [UIColor colorWithRed:41/255.0 green:41/255.0 blue:41/255.0 alpha:.46];
    [header_view addSubview:other_contacts_label];
    
//    UIView* grayBar =
//    [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
//    grayBar.backgroundColor = [self.tableView separatorColor];
//    grayBar.alpha = .5;
//    [header_view addSubview:grayBar];
    
    return header_view;
  }
  else
  {
    UIView* header_view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 25)];
    header_view.backgroundColor = [UIColor colorWithRed:243/255.0 green:243/255.0 blue:243/255.0 alpha:1];
    
    UILabel* my_contacts_label = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 200, 25)];
    my_contacts_label.text = @"My contacts on Infinit";
    my_contacts_label.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:10.5];
    my_contacts_label.textColor = [UIColor colorWithRed:41/255.0 green:41/255.0 blue:41/255.0 alpha:.46];
    [header_view addSubview:my_contacts_label];
    
//    UIView* grayBar = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
//    grayBar.backgroundColor = [self.tableView separatorColor];
//    grayBar.alpha = .5;
//    [header_view addSubview:grayBar];
    
    return header_view;
  }
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  //IF the cell is my computer show the popover view :-).
  /*
   [self showMyComputerView];
   */
  
  //Let's put the checkmark on here.  Put it into the dictionary too.
  //Redraw The Image as blurry, and put a check mark on it.
  
  if(indexPath.section == 0)
  {
    ContactCell* cell =
    (ContactCell*)[tableView cellForRowAtIndexPath:indexPath];
    if(self.selected_row == indexPath.row)
    {
      self.selected_row = -1;
    }
    else
    {
      self.selected_row = indexPath.row;
    }
    [tableView beginUpdates];
    [tableView endUpdates];
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
  }
}

- (IBAction)inviteBarButtonSelected:(id)sender
{
  self.invite_bar_button_view = [[UIView alloc] initWithFrame:  CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 44 + 20 + 49)];
  self.invite_bar_button_view.backgroundColor = [UIColor colorWithRed:81/255.0 green:81/255.0 blue:73/255.0 alpha:1];
  
  UIButton *importPhoneButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height + 20 + 49 - 267, self.view.frame.size.width - 54, 55)];
  [importPhoneButton setTitle:@"IMPORT PHONE CONTACTS" forState:UIControlStateNormal];
  [importPhoneButton setTitleColor:[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1]
                          forState:UIControlStateNormal];
  importPhoneButton.backgroundColor = [UIColor whiteColor];
  importPhoneButton.layer.cornerRadius = 2.5f;
  importPhoneButton.layer.borderWidth = 1.0f;
  importPhoneButton.layer.borderColor = ([[[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  importPhoneButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  [self.invite_bar_button_view addSubview:importPhoneButton];
  
  UIButton *findFacebookFriendsButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height + 20 + 49 - 199, self.view.frame.size.width - 54, 55)];
  [findFacebookFriendsButton setTitle:@"FIND FACEBOOK FRIENDS" forState:UIControlStateNormal];
  [findFacebookFriendsButton setTitleColor:[UIColor colorWithRed:42/255.0 green:108/255.0 blue:181/255.0 alpha:1]
                                  forState:UIControlStateNormal];
  [findFacebookFriendsButton setImage:[UIImage imageNamed:@"icon-facebook-blue"]
                             forState:UIControlStateNormal];
  findFacebookFriendsButton.backgroundColor = [UIColor whiteColor];
  findFacebookFriendsButton.layer.cornerRadius = 2.5f;
  findFacebookFriendsButton.layer.borderWidth = 1.0f;
  findFacebookFriendsButton.layer.borderColor = ([[[UIColor colorWithRed:42/255.0 green:108/255.0 blue:181/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  findFacebookFriendsButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  [self.invite_bar_button_view addSubview:findFacebookFriendsButton];
  
  UIButton *findPeopleButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height + 20 + 49 - 131, self.view.frame.size.width - 54, 55)];
  [findPeopleButton setTitle:@"FIND PEOPLE ON INFINIT" forState:UIControlStateNormal];
  [findPeopleButton setTitleColor:[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1]
                         forState:UIControlStateNormal];
  [findPeopleButton setImage:[UIImage imageNamed:@"icon-infinit-red"]
                    forState:UIControlStateNormal];
  findPeopleButton.backgroundColor = [UIColor whiteColor];
  findPeopleButton.layer.cornerRadius = 2.5f;
  findPeopleButton.layer.borderWidth = 1.0f;
  findPeopleButton.layer.borderColor = ([[[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  findPeopleButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  [self.invite_bar_button_view addSubview:findPeopleButton];
  
  UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(27, self.view.frame.size.height + 20 + 49 - 63, self.view.frame.size.width - 54, 55)];
  [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
  [cancelButton setTitleColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]
                     forState:UIControlStateNormal];
  cancelButton.layer.cornerRadius = 2.5f;
  cancelButton.layer.borderWidth = 1.0f;
  cancelButton.layer.borderColor = ([[UIColor whiteColor] CGColor]);
  cancelButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  [cancelButton addTarget:self
                   action:@selector(cancelInviteBarButtonView)
         forControlEvents:UIControlEventTouchUpInside];
  [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.invite_bar_button_view addSubview:cancelButton];
  
  UITapGestureRecognizer *dismissInviteButtonView =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(cancelInviteBarButtonView)];
  [self.invite_bar_button_view addGestureRecognizer:dismissInviteButtonView];
  
  
  [[[[UIApplication sharedApplication] delegate] window] addSubview:self.invite_bar_button_view];
}

- (void)cancelInviteBarButtonView
{
  [self.invite_bar_button_view removeFromSuperview];
}

@end
