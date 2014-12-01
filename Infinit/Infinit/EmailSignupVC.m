//
//  EmailSignupVC.m
//  Parlae
//
//  Created by Michael Dee on 8/15/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "EmailSignupVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/InfinitPeerTransactionManager.h>





@interface EmailSignupVC () <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>

- (void)processFieldEntries;
- (void)textInputChanged:(NSNotification *)note;
- (BOOL)shouldEnableDoneButton;

@property (nonatomic, strong) UIButton *personButton;
@property (nonatomic, strong) UIButton *storeButton;
@property (nonatomic, strong) UIButton *restaurantButton;

//Photo stuff.
@property (strong, nonatomic) UIImage *pickedImage;

@property (strong, nonatomic)  UIButton *signupButton;


@property NSInteger clickedButton;

//username checking
@property BOOL userNameIsUnique;
@property (strong, nonatomic) UIView *userNameStatus;
@property (strong, nonatomic) NSString *workableUsername;




@end

@implementation EmailSignupVC


@synthesize usernameField, passwordField, emailField, activityIndicator, backButton, workableUsername;

- (id)init
{
    self = [super init];
    
    
    if (self)
    {
        NSLog(@"inittted");
    }
    return self;
}


- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UISwipeGestureRecognizer *backSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popBack)];
    backSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:backSwipe];
    
    
    UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundImage.image = [UIImage imageNamed:@"login-background"];
    [self.view addSubview:backgroundImage];
    
    emailField = [[UITextField alloc] initWithFrame:CGRectMake(10, 170, 300, 30)];
    emailField.placeholder = @"email";
    emailField.font = [UIFont fontWithName:@"Myriad Pro" size:28];
    emailField.tintColor = [UIColor blackColor];
    emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
    emailField.delegate = self;
    emailField.textAlignment = NSTextAlignmentLeft;
    emailField.backgroundColor = [UIColor clearColor];
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:emailField];
    
    usernameField = [[UITextField alloc] initWithFrame:CGRectMake(10, 215, 200, 30)];
    usernameField.placeholder = @"username";
    usernameField.font = [UIFont fontWithName:@"Myriad Pro" size:28];
    usernameField.tintColor = [UIColor blackColor];
    usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    usernameField.delegate = self;
    usernameField.textAlignment = NSTextAlignmentLeft;
    usernameField.backgroundColor = [UIColor clearColor];
    usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if(_username)
    {
        usernameField.text = _username;
    }
    [self.view addSubview:usernameField];
    
    _userNameStatus = [[UIView alloc] initWithFrame:CGRectMake(220, 225, 15, 15)];
    _userNameStatus.layer.cornerRadius = 7.5f;
    _userNameStatus.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_userNameStatus];
    
    
    
    passwordField = [[UITextField alloc] initWithFrame:CGRectMake(10, 260, 200, 30)];
    passwordField.placeholder = @"password";
    passwordField.font = [UIFont fontWithName:@"Myriad Pro" size:28];
    passwordField.tintColor = [UIColor blackColor];
    passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    passwordField.delegate = self;
    passwordField.textAlignment = NSTextAlignmentLeft;
    passwordField.secureTextEntry = YES;
    passwordField.backgroundColor = [UIColor clearColor];
    passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if(_password)
    {
        passwordField.text = _password;
    }
    [self.view addSubview:passwordField];
    
    _clickedButton = 0;
    
    _personButton = [[UIButton alloc] initWithFrame:CGRectMake(6, 10, 102, 35)];
    [_personButton setImage:[UIImage imageNamed:@"person-clicked"] forState:UIControlStateSelected];
    [_personButton setImage:[UIImage imageNamed:@"person-unclicked"] forState:UIControlStateNormal];
    [_personButton addTarget:self action:@selector(toggleButton:) forControlEvents:UIControlEventTouchUpInside];
    _personButton.tag = 0;
    _personButton.adjustsImageWhenHighlighted = NO;
    _personButton.selected = YES;
    [self.view addSubview:_personButton];
    
    _restaurantButton = [[UIButton alloc] initWithFrame:CGRectMake(110, 10, 102, 35)];
    [_restaurantButton setImage:[UIImage imageNamed:@"restaurant-clicked"] forState:UIControlStateSelected];
    [_restaurantButton setImage:[UIImage imageNamed:@"restaurant-unclicked"] forState:UIControlStateNormal];
    [_restaurantButton addTarget:self action:@selector(toggleButton:) forControlEvents:UIControlEventTouchUpInside];
    _restaurantButton.tag = 1;
    _restaurantButton.adjustsImageWhenHighlighted = NO;
    [self.view addSubview:_restaurantButton];
    
    _storeButton = [[UIButton alloc] initWithFrame:CGRectMake(214, 10, 102, 35)];
    [_storeButton setImage:[UIImage imageNamed:@"store-unclicked"] forState:UIControlStateNormal];
    [_storeButton setImage:[UIImage imageNamed:@"store-clicked"] forState:UIControlStateSelected];
    [_storeButton addTarget:self action:@selector(toggleButton:) forControlEvents:UIControlEventTouchUpInside];
    _storeButton.tag = 2;
    _storeButton.adjustsImageWhenHighlighted = NO;
    [self.view addSubview:_storeButton];
    
    _signupButton = [[UIButton alloc] initWithFrame:CGRectMake(86, 305, 146, 40)];
    [_signupButton setImage:[UIImage imageNamed:@"sign-up-border"] forState:UIControlStateDisabled];
    [_signupButton setImage:[UIImage imageNamed:@"sign-up-green"] forState:UIControlStateNormal];
    [_signupButton addTarget:self action:@selector(processFieldEntries) forControlEvents:UIControlEventTouchUpInside];
    [_signupButton setTintColor:[UIColor blackColor]];
    [self.view addSubview:_signupButton];
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    usernameField.returnKeyType = UIReturnKeyDone;
    passwordField.returnKeyType = UIReturnKeyDone;
    emailField.returnKeyType = UIReturnKeyDone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:usernameField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:passwordField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:emailField];

    
	_signupButton.enabled = NO;
}

- (void)processFieldEntries {
	// Get the username text, store it in the app delegate for now
	NSString *username = usernameField.text;
	NSString *password = passwordField.text;
    NSString *email = emailField.text;
	NSString *noUsernameText = @"username";
	NSString *noPasswordText = @"password";
    NSString *noEmailText = @"email";
	NSString *errorText = @"No ";
	NSString *errorTextJoin = @" or ";
	NSString *errorTextEnding = @" entered";
	BOOL textError = NO;
    
	// Messaging nil will return 0, so these checks implicitly check for nil text.
	if (username.length == 0 || password.length == 0) {
		textError = YES;
        
		// Set up the keyboard for the first field missing input:
		if (password.length == 0) {
			[passwordField becomeFirstResponder];
		}
		if (username.length == 0) {
			[usernameField becomeFirstResponder];
		}
	}
    
	if (username.length == 0) {
		textError = YES;
		errorText = [errorText stringByAppendingString:noUsernameText];
	}
    
	if (password.length == 0) {
		textError = YES;
		errorText = [errorText stringByAppendingString:noPasswordText];
	}
    
    if (email.length == 0) {
		textError = YES;
		errorText = [errorText stringByAppendingString:noEmailText];
	}
    
	if (textError) {
		errorText = [errorText stringByAppendingString:errorTextEnding];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorText message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alertView show];
		return;
	}
    
	// Everything looks good; try to log in.
	// Disable the done button for now.
	_signupButton.enabled = NO;
    [activityIndicator startAnimating];
    
    [[InfinitStateManager sharedInstance] registerFullname:username email:email password:password performSelector:@selector(loginCallback:) onObject:self];
    
    /*
    PFUser *newUser = [PFUser user];
    newUser.username = usernameField.text;
    newUser.password = passwordField.text;
    newUser.email = emailField.text;
    [newUser setObject:_imageFile forKey:@"profileJPEG"];
    [newUser setObject:usernameField.text forKey:@"name"];

    
    if(_personButton.selected)
    {
        [newUser setObject:[NSNumber numberWithInt:1] forKey:@"type"];
    }
    if(_restaurantButton.selected)
    {
        [newUser setObject:[NSNumber numberWithInt:2] forKey:@"type"];
    }
    if(_storeButton.selected)
    {
        [newUser setObject:[NSNumber numberWithInt:3] forKey:@"type"];
    }
    
 
    
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded)
        {
            //LEt's do something else.
            SecretTextViewController *newVC = [[SecretTextViewController alloc] init];
            [self.navigationController pushViewController:newVC animated:YES];
            
     
            UITabBarController *myTabBar = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"homeTabBar"];
            [self presentViewController:myTabBar animated:YES completion:nil];
     
     
            
        } else {
            // Re-enable the done button if we're tossing them back into the form.
			_signupButton.enabled = [self shouldEnableDoneButton];
			UIAlertView *alertView = nil;
            
			if (error == nil) {
				// the username or password is probably wrong.
				alertView = [[UIAlertView alloc] initWithTitle:@"Couldn’t log in:\nThe username or password were wrong." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			} else {
				// Something else went horribly wrong:
				alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			}
			[alertView show];
			// Bring the keyboard back up, because they'll probably need to change something.
			[usernameField becomeFirstResponder];
        }
        
    }];
*/

}

- (BOOL)shouldEnableDoneButton {
	BOOL enableDoneButton = NO;
	if (usernameField.text != nil &&
		usernameField.text.length > 0 &&
		passwordField.text != nil &&
		passwordField.text.length > 0 &&
        emailField.text != nil &&
		emailField.text.length > 0)
//       && _userNameIsUnique) {
    {
		enableDoneButton = YES;
	}
	return enableDoneButton;
}



- (void)btnBack:(id)sender
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


- (void)textInputChanged:(NSNotification *)note
{
	_signupButton.enabled = [self shouldEnableDoneButton];
    
    if(note.object == usernameField)
    {
        //Don't do this anymore.  Can implement later.
//        [self checkUserName];
    }

}



- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == emailField) {
		[usernameField becomeFirstResponder];
	}
	if (textField == usernameField) {
		[passwordField becomeFirstResponder];
	}
	if (textField == passwordField) {
        
        [passwordField resignFirstResponder];
	}
    
	return YES;
}



-(void)toggleButton:(UIButton *)sender
{
    //If sender is the same do nothing.
    if(sender.tag == _clickedButton)
    {
        return;
    } else {
        if(sender.tag == 0) {
            _personButton.selected = YES;
            _restaurantButton.selected = NO;
            _storeButton.selected = NO;
            _clickedButton = 0;
        } else if (sender.tag == 1) {
            _personButton.selected = NO;
            _restaurantButton.selected = YES;
            _storeButton.selected = NO;
            _clickedButton = 1;
        } else {
            _personButton.selected = NO;
            _restaurantButton.selected = NO;
            _storeButton.selected = YES;
            _clickedButton = 2;
        }
    }
}



- (void)loginCallback:(InfinitStateResult*)result
{
    if (result.success)
    {
        [InfinitUserManager sharedInstance];
        [InfinitPeerTransactionManager sharedInstance];
        [self performSegueWithIdentifier:@"logged_in" sender:self];
    }
    else
    {
        NSLog([NSString stringWithFormat:@"Error: %d", result.status]);
    }
}


- (void)popBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

-  (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:usernameField];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:passwordField];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:emailField];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
