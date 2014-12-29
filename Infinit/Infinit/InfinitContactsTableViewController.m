//
//  InfinitContactsTableViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/21/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitContactsTableViewController.h"
#import <AddressBook/AddressBook.h>
#import "CGLContact.h"
#import "CGLAlphabetizer.h"
#import "ContactCell.h"
#import "ImportContactsCell.h"
#import "ContactOtherCell.h"




@interface InfinitContactsTableViewController ()

@property (strong, nonatomic) NSMutableArray* people;
@property (strong, nonatomic) NSArray* alphabetIndexes;
@property (strong, nonatomic) NSDictionary* sortedContacts;
@property (strong, nonatomic) NSMutableDictionary* cleanedContacts;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButton;
@property (strong, nonatomic) UIView *inviteBarButtonView;


@property int selectedRow;

@end

@implementation InfinitContactsTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  //Do this so that selected row isnt in the indexPath row space yet.
  _selectedRow = -1;
  
  NSDictionary * attributes = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:18]};
  [_inviteBarButton setTitleTextAttributes:attributes forState:UIControlStateNormal];

  [self fetchContacts];
}

-(void)fetchContacts
{
  CFErrorRef *error = nil;
  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
  
  __block BOOL accessGranted = NO;
  if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6 or later.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
      accessGranted = granted;
      dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
  }
  else { // we're on iOS 5 or older
    accessGranted = YES;
  }
  
  if (accessGranted) {
    
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
    
    _people = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < CFArrayGetCount(allPeople); i++)
    {
      ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
      if(person)
      {
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        CGLContact *contact = [[CGLContact alloc] init];

        if(firstName && lastName)
        {
          [contact setFirstName:firstName];
          [contact setLastName:lastName];
        }
        else if(firstName)
        {
          [contact setFirstName:firstName];
        }
        else if(lastName)
        {
          [contact setLastName:lastName];
        }
        /*
        NSData  *imgData = (__bridge NSData *)ABPersonCopyImageData(person);
        UIImage *image = [UIImage imageWithData:imgData];
        if(image)
        {
          [userDict setObject:image forKey:@"avatar"];
        }
         */
        
        [_people addObject:contact];
      }
    }
    //Now sort the people array.
    _sortedContacts = [CGLAlphabetizer alphabetizedDictionaryFromObjects:_people usingKeyPath:@"firstName"];
    
    _alphabetIndexes = [CGLAlphabetizer indexTitlesFromAlphabetizedDictionary:_sortedContacts];
    
    [self.tableView reloadData];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  
  /*  Phone book logic.  Sections for the alphabet.
  if([_alphabetIndexes containsObject:@"#"])
  {
    NSMutableArray* purgeArray = [NSMutableArray arrayWithArray:_alphabetIndexes];
    [purgeArray removeObject:@"#"];
    _alphabetIndexes = [NSArray arrayWithArray:purgeArray];
  }

  
  if(_alphabetIndexes)
  {
    return _alphabetIndexes.count;
  } else {
    return 0;
  }
   
   */
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if(section == 0)
    return 1;
  else
    return 10;
  
  /* Phone book logic.  How many contacts in each letter of the alphabet.
  NSArray *array = _sortedContacts[_alphabetIndexes[section]];
  if(array)
  {
    return array.count;
  } else {
    return 0;
  }
   */
}

- (UITableViewCell*)tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if(indexPath.section == 0)
  {
    ContactCell* cell = (ContactCell*)[tableView dequeueReusableCellWithIdentifier:@"contactCell"
                                                                forIndexPath:indexPath];
    
    cell.nameLabel.text = @"My Computer";
    /*
     NSString *name = [_people[indexPath.row] objectForKey:@"fullname"];
     if(name)
     {
     cell.nameLabel.text = name;
     }
     
     UIImage *image = [_people[indexPath.row] objectForKey:@"avatar"];
     if(image)
     {
     cell.avatarImageView.image = image;
     }
     */
    
    return cell;
  }
  else
  {
    ContactOtherCell* cell = (ContactOtherCell*)[tableView dequeueReusableCellWithIdentifier:@"otherContactCell"
                                                                      forIndexPath:indexPath];
    
    
    return cell;
    /* IF we don't have anybody.
    ImportContactsCell* cell = (ImportContactsCell*)[tableView dequeueReusableCellWithIdentifier:@"importCell"
                                                                                  forIndexPath:indexPath];
     [cell.importPhoneContactsButton addTarget:self action:@selector(importPhoneContacts) forControlEvents:UIControlEventTouchUpInside];
     [cell.importFacebookButton addTarget:self action:@selector(importFacebookContacts) forControlEvents:UIControlEventTouchUpInside];
     [cell.findPeopleButton addTarget:self action:@selector(findPeopleButton) forControlEvents:UIControlEventTouchUpInside];
    return cell;
     */
  }
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  
  if (section == 1)
  {
    CGFloat height = 25.0;
    return height;
  } else
  {
    CGFloat height = 25.0;
    return height;
  }
  
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 0)
  {
    if(indexPath.row == _selectedRow)
    {
      return 100;
    } else {
      return 50;
    }
  } else {
    return 55;
    //IF its the invite one make it 349.
  }
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  if (section == 1)
  {
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)];
    headerView.backgroundColor = [UIColor colorWithRed:243/255.0 green:243/255.0 blue:243/255.0 alpha:1];
    
    UILabel* otherContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 200, 25)];
    otherContactsLabel.text = @"Other contacts";
    otherContactsLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:10.5];
    otherContactsLabel.textColor = [UIColor colorWithRed:41/255.0 green:41/255.0 blue:41/255.0 alpha:.46];
    [headerView addSubview:otherContactsLabel];
    
//    UIView* grayBar = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
//    grayBar.backgroundColor = [self.tableView separatorColor];
//    grayBar.alpha = .5;
//    [headerView addSubview:grayBar];
    
    return headerView;
  } else
  {
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)];
    headerView.backgroundColor = [UIColor colorWithRed:243/255.0 green:243/255.0 blue:243/255.0 alpha:1];
    
    UILabel* myContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 200, 25)];
    myContactsLabel.text = @"My contacts on Infinit";
    myContactsLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:10.5];
    myContactsLabel.textColor = [UIColor colorWithRed:41/255.0 green:41/255.0 blue:41/255.0 alpha:.46];
    [headerView addSubview:myContactsLabel];
    
//    UIView* grayBar = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
//    grayBar.backgroundColor = [self.tableView separatorColor];
//    grayBar.alpha = .5;
//    [headerView addSubview:grayBar];
    
    return headerView;
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
  ContactCell* cell = (ContactCell*)[tableView cellForRowAtIndexPath:indexPath];
  
  if(_selectedRow == indexPath.row)
  {
    _selectedRow = -1;
  } else {
    _selectedRow = indexPath.row;
  }
  [tableView beginUpdates];
  [tableView endUpdates];
  
  [tableView deselectRowAtIndexPath:indexPath
                           animated:NO];
  
}
- (IBAction)inviteBarButtonSelected:(id)sender
{
  _inviteBarButtonView = [[UIView alloc] initWithFrame:  CGRectMake(0, 0, 320, 568)];
  _inviteBarButtonView.backgroundColor = [UIColor colorWithRed:81/255.0 green:81/255.0 blue:73/255.0 alpha:1];
  
  UIButton *importPhoneButton = [[UIButton alloc] initWithFrame:CGRectMake(27, 271, 266, 55)];
  [importPhoneButton setTitle:@"IMPORT PHONE CONTACTS" forState:UIControlStateNormal];
  [importPhoneButton setTitleColor:[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1]
                          forState:UIControlStateNormal];
  importPhoneButton.backgroundColor = [UIColor whiteColor];
  importPhoneButton.layer.cornerRadius = 2.5f;
  importPhoneButton.layer.borderWidth = 1.0f;
  importPhoneButton.layer.borderColor = ([[[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  importPhoneButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:10.5];
  [_inviteBarButtonView addSubview:importPhoneButton];
  
  UIButton *findFacebookFriendsButton = [[UIButton alloc] initWithFrame:CGRectMake(27, 339, 266, 55)];
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
  [_inviteBarButtonView addSubview:findFacebookFriendsButton];
  
  UIButton *findPeopleButton = [[UIButton alloc] initWithFrame:CGRectMake(27, 407, 266, 55)];
  [findPeopleButton setTitle:@"FIND PEOPLE ON INFINIT" forState:UIControlStateNormal];
  [findPeopleButton setTitleColor:[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1]
                         forState:UIControlStateNormal];
  [findPeopleButton setImage:[UIImage imageNamed:@"icon-infinit-red"]
                    forState:UIControlStateNormal];
  findPeopleButton.backgroundColor = [UIColor whiteColor];
  findPeopleButton.layer.cornerRadius = 2.5f;
  findPeopleButton.layer.borderWidth = 1.0f;
  findPeopleButton.layer.borderColor = ([[[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  findPeopleButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:10.5];
  [_inviteBarButtonView addSubview:findPeopleButton];
  
  UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(27, 475, 266, 55)];
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
  cancelButton.titleLabel.textColor = [UIColor whiteColor];
  [_inviteBarButtonView addSubview:cancelButton];
  
  UITapGestureRecognizer *dismissInviteButtonView =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(cancelInviteBarButtonView)];
  [_inviteBarButtonView addGestureRecognizer:dismissInviteButtonView];
  
  
  [[[[UIApplication sharedApplication] delegate] window] addSubview:_inviteBarButtonView];
}

- (void)cancelInviteBarButtonView
{
  [_inviteBarButtonView removeFromSuperview];
}

@end
