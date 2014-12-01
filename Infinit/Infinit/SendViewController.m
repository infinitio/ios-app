//
//  SendViewController.m
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "SendViewController.h"
#import "SendCell.h"

@interface SendViewController () <UITableViewDataSource, UITableViewDelegate>

@property NSArray* peopleArray;
@property (nonatomic, strong) NSMutableDictionary* selectedRecipients;
@property (nonatomic, strong) UIButton* sendButton;

@end

@implementation SendViewController
@synthesize peopleArray;

- (id)initWithNibName:(NSString*)nibNameOrNil
               bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height - 50)
                                                          style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView setSeparatorInset:UIEdgeInsetsZero];
    [tableView registerClass:[SendCell class]
      forCellReuseIdentifier:@"sendcell"];
    [self.view addSubview:tableView];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Do a send button.  To people.
    //The height of the screen - the button size - the navbar size - the status bar size.
    _sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 49 - 50, 320, 50)];
    _sendButton.backgroundColor = [UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1];
    [_sendButton setTitle:@"Send (0 Selected)"
                 forState:UIControlStateNormal];
    [_sendButton addTarget:self
                    action:@selector(sendButtonSelected)
          forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_sendButton];
    
    [self loadPeople];
}

- (void)loadPeople
{
    //Load Fake Stuff
    NSDictionary* Mike = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Mike", @"name",
                          [UIImage imageNamed:@"dogimage.jpeg"], @"picture",
                          @"Important Cat Stuff", @"note",
                          @"1w", @"time",
                          nil];
    NSDictionary* Gaetan = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"Gaetan", @"name",
                            [UIImage imageNamed:@"catimage.jpeg"], @"picture",
                            @"Important Cat Stuff", @"note",
                            @"1w", @"time",
                            nil];
    NSDictionary* Julien = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"Julien", @"name",
                            [UIImage imageNamed:@"turkeyimage.jpeg"], @"picture",
                            @"Important Cat Stuff", @"note",
                            @"1w", @"time",
                            nil];
    NSDictionary* Mefyl = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Mefyl", @"name",
                           [UIImage imageNamed:@"beardimage.jpeg"], @"picture",
                           @"Important Cat Stuff", @"note",
                           @"1w", @"time",
                           nil];
    NSDictionary* Chicken = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Rubber Chicken", @"name",
                             [UIImage imageNamed:@"chickenimage.jpeg"], @"picture",
                             @"Important Cat Stuff", @"note",
                             @"1w", @"time",
                             nil];
    NSDictionary* Chris = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Chris", @"name",
                          [UIImage imageNamed:@"turtleimage.jpeg"], @"picture",
                          @"Important Cat Stuff", @"note",
                          @"1w", @"time",
                          nil];
    
    peopleArray = [NSArray arrayWithObjects:Mike, Gaetan, Julien, Mefyl, Chris, Chicken, nil];
}

# pragma mark TableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return peopleArray.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* CellIdentifier = @"sendcell";
    
    SendCell* cell = (SendCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SendCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.nameLabel.text = [[peopleArray objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    cell.portraitImageView.image = [[peopleArray objectAtIndex:indexPath.row] objectForKey:@"picture"];
    
    return cell;
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
        cell.checkMark.image = [UIImage imageNamed:@"icon-contact-select"];
        [_selectedRecipients removeObjectForKey:indexPath];
        
        NSString* buttonString = [NSString stringWithFormat:@"Send (%lu Selected)", (unsigned long)_selectedRecipients.allKeys.count];
        [_sendButton setTitle:buttonString
                     forState:UIControlStateNormal];
    }
    else
    {
        cell.checkMark.image = [UIImage imageNamed:@"icon-contact-selected"];
        [_selectedRecipients setObject:indexPath forKey:indexPath];
        
        NSString* buttonString = [NSString stringWithFormat:@"Send (%lu Selected)", (unsigned long)_selectedRecipients.allKeys.count];
        [_sendButton setTitle:buttonString
                     forState:UIControlStateNormal];
    }
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 43;
}

- (void)sendButtonSelected
{
    //Do the actual send here.  Need the files, plus the recipients.
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
