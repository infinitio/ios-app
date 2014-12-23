//
//  InfinitSelectPeopleViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSelectPeopleViewController.h"
#import "SendCell.h"
#import "ImportContactsCell.h"
#import <AddressBook/AddressBook.h>
#import "Gap/InfinitUser.h"
#import "inviteView.h"

@interface InfinitSelectPeopleViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField* searchTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *optionNoteTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButton;
@property (strong, nonatomic) UIView *inviteBarButtonView;
@property (strong, nonatomic) UIView *myComputerView;

@property (strong, nonatomic) NSMutableArray *people;



@property (strong, nonatomic) NSMutableDictionary *selectedRecipients;

@end

@implementation InfinitSelectPeopleViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  NSDictionary * attributes = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:14]};
  [_inviteBarButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
  
  _sendButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  
  [[NSBundle mainBundle] loadNibNamed:@"inviteView" owner:self options:nil];

//  self.topGrayBar.backgroundColor = [self.tableView separatorColor];
//  self.bottomGrayBar.backgroundColor = [self.tableView separatorColor];
  
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
  if(section == 0)
  {
    return 1;
  } else
  {
    //Return 1 if its not right
    return 1;
//    return _people.count;
  }
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if(indexPath.section == 0)
  {
    SendCell* cell = (SendCell*)[tableView dequeueReusableCellWithIdentifier:@"sendCell"
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
    
    if([_selectedRecipients objectForKey:indexPath])
    {
      cell.checkMark.image = [UIImage imageNamed:@"icon-contact-checked"];
    } else
    {
      cell.checkMark.image = [UIImage imageNamed:@"icon-contact-check"];
    }
     
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
    return 61;
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
    headerView.backgroundColor = [UIColor colorWithRed:216/255.0 green:216/255.0 blue:216/255.0 alpha:1];
    
    UILabel* otherContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 200, 25)];
    otherContactsLabel.text = @"Other contacts";
    otherContactsLabel.font = [UIFont systemFontOfSize:10];
    otherContactsLabel.textColor = [UIColor colorWithRed:41/255.0 green:41/255.0 blue:41/255.0 alpha:1];
    [headerView addSubview:otherContactsLabel];
    
    UIView* grayBar = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
    grayBar.backgroundColor = [self.tableView separatorColor];
    grayBar.alpha = .5;
    [headerView addSubview:grayBar];
    
    return headerView;
  } else
  {
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)];
    headerView.backgroundColor = [UIColor colorWithRed:216/255.0 green:216/255.0 blue:216/255.0 alpha:1];
    
    UILabel* myContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 200, 25)];
    myContactsLabel.text = @"My contacts on Infinit";
    myContactsLabel.font = [UIFont systemFontOfSize:10];
    myContactsLabel.textColor = [UIColor colorWithRed:41/255.0 green:41/255.0 blue:41/255.0 alpha:1];
    [headerView addSubview:myContactsLabel];
    
    UIView* grayBar = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 258, 1)];
    grayBar.backgroundColor = [self.tableView separatorColor];
    grayBar.alpha = .5;
    [headerView addSubview:grayBar];
    
    return headerView;
  }
}


#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  //IF the cell is my computer show the popover view :-).
  /*
  [self showMyComputerView];
   */
  
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
    
    if(_selectedRecipients.allKeys.count == 0)
    {
      self.sendButton.hidden = YES;
    }
  }
  else
  {
    self.sendButton.hidden = NO;
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
  importPhoneButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
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
  findPeopleButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
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
  
  
  [[[[UIApplication sharedApplication] delegate] window] addSubview:_inviteBarButtonView];
}

- (void)cancelInviteBarButtonView
{
  [_inviteBarButtonView removeFromSuperview];
}

- (void)showMyComputerView
{
  _myComputerView = [[UIView alloc] initWithFrame:  CGRectMake(0, 0, 320, 568)];
  _myComputerView.backgroundColor = [UIColor colorWithRed:81/255.0 green:81/255.0 blue:73/255.0 alpha:1];
  
  UILabel *boldLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 142, 250, 70)];
  boldLabel.text = @"You have Infinit installed on \n 2 other devices.";
  boldLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:20];
  boldLabel.numberOfLines = 2;
  boldLabel.textAlignment = NSTextAlignmentCenter;
  boldLabel.textColor = [UIColor whiteColor];
  [_myComputerView addSubview:boldLabel];
  
  UILabel *lightLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 249, 250, 77)];
  lightLabel.text = @"A notification will be sent to \n your 2 devices. Accept the files \n on the device you want!";
  lightLabel.numberOfLines = 3;
  lightLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
  lightLabel.textAlignment = NSTextAlignmentCenter;
  lightLabel.textColor = [UIColor whiteColor];
  [_myComputerView addSubview:lightLabel];
  
  UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(27, 475, 266, 55)];
  [cancelButton setTitle:@"GOT IT" forState:UIControlStateNormal];
  [cancelButton setTitleColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]
                     forState:UIControlStateNormal];
  cancelButton.titleLabel.textColor = [UIColor whiteColor];
  cancelButton.layer.cornerRadius = 2.5f;
  cancelButton.layer.borderWidth = 1.0f;
  cancelButton.layer.borderColor = ([[UIColor whiteColor] CGColor]);
  cancelButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  [cancelButton addTarget:self
                   action:@selector(cancelMyComputerView)
         forControlEvents:UIControlEventTouchUpInside];
  [_myComputerView addSubview:cancelButton];
  
  
  [[[[UIApplication sharedApplication] delegate] window] addSubview:_myComputerView];
}

- (void)cancelMyComputerView
{
  [_myComputerView removeFromSuperview];
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
