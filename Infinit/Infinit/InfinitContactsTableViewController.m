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


@interface InfinitContactsTableViewController ()

@property (strong, nonatomic) NSMutableArray* people;

@property (strong, nonatomic) NSArray* alphabetIndexes;

@property (strong, nonatomic) NSDictionary* sortedContacts;
@property (strong, nonatomic) NSMutableDictionary* cleanedContacts;




@end

@implementation InfinitContactsTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

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
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  
  NSArray *array = _sortedContacts[_alphabetIndexes[section]];
  if(array)
  {
    return array.count;
  } else {
    return 0;

  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
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
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  CGFloat height = 45.0;
  return height;
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{

  UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
  headerView.backgroundColor = [UIColor lightGrayColor];
  
  UILabel* otherContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, 100, 25)];
  otherContactsLabel.text = _alphabetIndexes[section];
  otherContactsLabel.font = [UIFont systemFontOfSize:20];
  otherContactsLabel.textColor = [UIColor blackColor];
  [headerView addSubview:otherContactsLabel];
  
  return headerView;

}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  return _alphabetIndexes;
}

- (NSInteger)tableView:(UITableView*)tableView
sectionForSectionIndexTitle:(NSString*)title
               atIndex:(NSInteger)index
{
  return index;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
