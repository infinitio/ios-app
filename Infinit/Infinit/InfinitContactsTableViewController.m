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
#import "SendCell.h"



@interface InfinitContactsTableViewController ()

@property (strong, nonatomic) NSMutableArray* people;
@property (strong, nonatomic) NSArray* alphabetIndexes;
@property (strong, nonatomic) NSDictionary* sortedContacts;
@property (strong, nonatomic) NSMutableDictionary* cleanedContacts;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButton;

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
    return 1;
  
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
    ImportContactsCell* cell = (ImportContactsCell*)[tableView dequeueReusableCellWithIdentifier:@"importCell"
                                                                                    forIndexPath:indexPath];
    /*
     [cell.importPhoneContactsButton addTarget:self action:@selector(importPhoneContacts) forControlEvents:UIControlEventTouchUpInside];
     [cell.importFacebookButton addTarget:self action:@selector(importFacebookContacts) forControlEvents:UIControlEventTouchUpInside];
     [cell.findPeopleButton addTarget:self action:@selector(findPeopleButton) forControlEvents:UIControlEventTouchUpInside];
     */
    return cell;
  }

  
  /* Phone book style like whatsapp.
  ContactCell *cell = (ContactCell*)[tableView dequeueReusableCellWithIdentifier:@"contactCell"
                                                          forIndexPath:indexPath];
  
  // Configure the cell...
  NSString *sectionIndexTitle = _alphabetIndexes[indexPath.section];
  CGLContact *contact = _sortedContacts[sectionIndexTitle][indexPath.row];
  
  if(contact.firstName && contact.lastName)
  {
    cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
  }
  else if(contact.firstName)
  {
    cell.nameLabel.text = contact.firstName;
  }
  else if(contact.lastName)
  {
    cell.nameLabel.text = contact.lastName;
  }
  
  
  return cell;
   */
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
    return 349;
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

@end
