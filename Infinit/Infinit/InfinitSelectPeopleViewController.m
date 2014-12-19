//
//  InfinitSelectPeopleViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSelectPeopleViewController.h"
#import "SendCell.h"
#import <AddressBook/AddressBook.h>
#import "Gap/InfinitUser.h"

@interface InfinitSelectPeopleViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField* searchTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *optionNoteTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *topGrayBar;
@property (weak, nonatomic) IBOutlet UIView *bottomGrayBar;

@property (strong, nonatomic) NSMutableArray *people;



@property (strong, nonatomic) NSMutableDictionary *selectedRecipients;

@end

@implementation InfinitSelectPeopleViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  
  self.topGrayBar.backgroundColor = [self.tableView separatorColor];
  self.bottomGrayBar.backgroundColor = [self.tableView separatorColor];
  
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
        
        NSMutableDictionary *userDict = [[NSMutableDictionary alloc] init];
        if(firstName && lastName)
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
        
        [_people addObject:userDict];
      }
    }
  }
}

- (IBAction)backButtonSelected:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)shareLinkButtonSelected:(id)sender
{
  
}

- (IBAction)sendButtonSelected:(id)sender
{
  
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if(_people)
  {
    if(section == 0)
    {
      if(_people.count > 5)
      {
        return 5;
      } else
      {
        return _people.count;
      }
    } else if(section == 1)
    {
      if(_people.count > 5)
      {
        return _people.count - 5;
      } else
      {
        return 0;
      }
    }
  }
  return 0;
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  SendCell* cell = (SendCell*)[tableView dequeueReusableCellWithIdentifier:@"sendCell"
                                                              forIndexPath:indexPath];
  
  
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
  
  if([_selectedRecipients objectForKey:indexPath])
  {
    cell.checkMark.image = [UIImage imageNamed:@"icon-contact-checked"];
  } else
  {
    cell.checkMark.image = [UIImage imageNamed:@"icon-contact-check"];
  }

  
  return cell;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  
  if (section == 1)
  {
    CGFloat height = 38.0;
    return height;
  } else {
    CGFloat height = 0.0;
    return height;
  }
  
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  if (section == 1)
  {
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    UILabel* otherContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 15, 100, 10)];
    otherContactsLabel.text = @"OTHER CONTACTS";
    otherContactsLabel.font = [UIFont systemFontOfSize:8];
    otherContactsLabel.textColor = [UIColor blackColor];
    [headerView addSubview:otherContactsLabel];
    
    UIView* grayBar = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
    grayBar.backgroundColor = [self.tableView separatorColor];
    grayBar.alpha = .5;
    [headerView addSubview:grayBar];
    
    return headerView;
  } else
  {
    return nil;
  }
}


#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  //Let's put the checkmark on here.  Put it into the dictionary too.
  //Redraw The Image as blurry, and put a check mark on it.
  SendCell* cell = (SendCell*)[tableView cellForRowAtIndexPath:indexPath];
  
  if(_selectedRecipients == nil)
  {
    _selectedRecipients = [[NSMutableDictionary alloc] init];
  }
  
  if([_selectedRecipients objectForKey:indexPath])
  {
    cell.checkMark.image = [UIImage imageNamed:@"icon-contact-check"];
    [_selectedRecipients removeObjectForKey:indexPath];
    
    NSString* buttonString = [NSString stringWithFormat:@"SEND (%lu)", (unsigned long)_selectedRecipients.allKeys.count];
    [_sendButton setTitle:buttonString
                 forState:UIControlStateNormal];
  }
  else
  {
    cell.checkMark.image = [UIImage imageNamed:@"icon-contact-checked"];
    [_selectedRecipients setObject:indexPath forKey:indexPath];
    
    NSString* buttonString = [NSString stringWithFormat:@"SEND (%lu)", (unsigned long)_selectedRecipients.allKeys.count];
    [_sendButton setTitle:buttonString
                 forState:UIControlStateNormal];
  }
  [tableView deselectRowAtIndexPath:indexPath
                           animated:NO];
  
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
