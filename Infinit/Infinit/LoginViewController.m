//
//  SplashPageViewController.m
//  Three
//
//  Created by Michael Dee on 8/26/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "LoginViewController.h"
#import "EmailSignupVC.h"
#import <Parse/Parse.h>


@interface LoginViewController () <UITextFieldDelegate>



@property (nonatomic, strong) UIImageView *firstBackground;
@property (nonatomic, strong) UIImageView *hoochLogo;

@property (nonatomic, strong) NSArray *stringsForBottom;
@property (nonatomic, strong) NSArray *stringsForTop;

//Second Phase
@property (strong, nonatomic) UIView *graySquareView;
@property (strong, nonatomic)  UITextField *usernameField;
@property (strong, nonatomic)  UITextField *passwordField;
@property (strong, nonatomic)  UIButton *loginButton;
@property (strong, nonatomic)  UIButton *signupButton;

@property (strong, nonatomic)  UIView *dividingLine;
@property (strong, nonatomic)  UIImageView *getTakenCareOfImage;


@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    _firstBackground = [[UIImageView alloc] initWithFrame:self.view.frame];
    _firstBackground.image = [UIImage imageNamed:@"background-first-page-"];
    [self.view addSubview:_firstBackground];
  
    _hoochLogo = [[UIImageView alloc] initWithFrame:CGRectMake(70, 180, 180, 50)];
    _hoochLogo.image = [UIImage imageNamed:@"hooch"];
    [self.view addSubview:_hoochLogo];
  
    _getTakenCareOfImage = [[UIImageView alloc] initWithFrame:CGRectMake(17, 286, 184, 22)];
    _getTakenCareOfImage.image = [UIImage imageNamed:@"get-taken-care-of"];
    [self.view addSubview:_getTakenCareOfImage];

    _dividingLine = [[UIView alloc] initWithFrame:CGRectMake(0, 268, 320, 4)];
    _dividingLine.backgroundColor = [UIColor colorWithRed:8/255.0 green:167/255.0 blue:157/255.0 alpha:1];
    [self.view addSubview:_dividingLine];
  
  
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginSecondPhase)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    //Second Phase
    _graySquareView = [[UIView alloc] initWithFrame:CGRectMake(0, -200, 320, 200)];
    _graySquareView.backgroundColor = [UIColor colorWithRed:237/255.0 green:236/255.0 blue:236/255.0 alpha:1];
    [self.view addSubview:_graySquareView];
    
    _usernameField = [[UITextField alloc] initWithFrame:CGRectMake(13, 40, 200, 40)];
    _usernameField.placeholder = @"username";
    _usernameField.font = [UIFont systemFontOfSize:20];
    _usernameField.tintColor = [UIColor blackColor];
    _usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameField.delegate = self;
    _usernameField.textAlignment = NSTextAlignmentLeft;
    _usernameField.backgroundColor = [UIColor clearColor];
    _usernameField.layer.cornerRadius = 3;
    [_graySquareView addSubview:_usernameField];
    
    _passwordField = [[UITextField alloc] initWithFrame:CGRectMake(13, 90, 200, 40)];
    _passwordField.placeholder = @"password";
    _passwordField.font = [UIFont systemFontOfSize:20];
    _passwordField.tintColor = [UIColor blackColor];
    _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordField.delegate = self;
    _passwordField.textAlignment = NSTextAlignmentLeft;
    _passwordField.secureTextEntry = YES;
    _passwordField.backgroundColor = [UIColor clearColor];
    _passwordField.layer.cornerRadius = 3;
    [_graySquareView addSubview:_passwordField];
    
    _loginButton = [[UIButton alloc] initWithFrame:CGRectMake(13, 155, 142, 36)];
    [_loginButton setImage:[UIImage imageNamed:@"login-button-1"] forState:UIControlStateNormal];
    [_loginButton addTarget:self action:@selector(loginClicked:) forControlEvents:UIControlEventTouchUpInside];
    _loginButton.adjustsImageWhenHighlighted = NO;
    _loginButton.backgroundColor = [UIColor greenColor];
    [_graySquareView addSubview:_loginButton];
    
    _signupButton = [[UIButton alloc] initWithFrame:CGRectMake(165, 155, 142, 36)];
    [_signupButton setImage:[UIImage imageNamed:@"sign-up-button"] forState:UIControlStateNormal];
    [_signupButton addTarget:self action:@selector(signupClicked:) forControlEvents:UIControlEventTouchUpInside];
    _signupButton.adjustsImageWhenHighlighted = NO;
    _signupButton.backgroundColor = [UIColor greenColor];
    [_graySquareView addSubview:_signupButton];
    

    _usernameField.returnKeyType = UIReturnKeyDone;
    _passwordField.returnKeyType = UIReturnKeyDone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:_usernameField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:_passwordField];
    

}




- (void)beginSecondPhase
 {
     //Now we go to second phase.
     self.view.gestureRecognizers = nil;

     
     [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionTransitionCurlUp animations:^{

       [_dividingLine removeFromSuperview];
       [_getTakenCareOfImage removeFromSuperview];
       
       _firstBackground.frame = CGRectMake(0,self.view.frame.size.height,320,self.view.frame.size.height);
       _graySquareView.frame = CGRectMake(0, 0, 320, 200);
       
       _hoochLogo.frame = CGRectMake(70, 250, 180, 50);
       
         
         
     }completion:^(BOOL finished){
         [_usernameField becomeFirstResponder];
         
     }];
     
     /*
    UIViewController *nextVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"GWelcome"];
    [self presentViewController:nextVC animated:NO completion:nil];
      */
}

- (void)loginClicked:(id)sender
{
    // Get the username text, store it in the app delegate for now
	NSString *username = _usernameField.text;
	NSString *password = _passwordField.text;
	NSString *noUsernameText = @"username";
	NSString *noPasswordText = @"password";
	NSString *errorText = @"No ";
	NSString *errorTextJoin = @" or ";
	NSString *errorTextEnding = @" entered";
	BOOL textError = NO;
    
	// Messaging nil will return 0, so these checks implicitly check for nil text.
	if (username.length == 0 || password.length == 0) {
		textError = YES;
        
		// Set up the keyboard for the first field missing input:
		if (password.length == 0) {
			[_passwordField becomeFirstResponder];
		}
		if (username.length == 0) {
			[_usernameField becomeFirstResponder];
		}
	}
    
	if (username.length == 0) {
		textError = YES;
		errorText = [errorText stringByAppendingString:noUsernameText];
	}
    
	if (password.length == 0) {
		textError = YES;
		if (username.length == 0) {
			errorText = [errorText stringByAppendingString:errorTextJoin];
		}
		errorText = [errorText stringByAppendingString:noPasswordText];
	}
    
	if (textError) {
		errorText = [errorText stringByAppendingString:errorTextEnding];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorText message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alertView show];
		return;
	}
    

    //Do the custom one.
//    [activityIndicator startAnimating];
    
	[PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
		// Tear down the activity view in all cases.
        
		if (user) {
            //Then Let Us segway
            
            UITabBarController *myTabBar = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"homeTabBar"];
            [self presentViewController:myTabBar animated:YES completion:nil];
            
		}
        else {
			// Didn't get a user.
			NSLog(@"%s didn't get a user!", __PRETTY_FUNCTION__);
            
			// Re-enable the done button if we're tossing them back into the form.
			UIAlertView *alertView = nil;
            
			if (error == nil) {
				// the username or password is probably wrong.
				alertView = [[UIAlertView alloc] initWithTitle:@"Couldn’t log in:\nThe username and password don't match." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			} else {
				// Something else went horribly wrong:
				alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			}
			[alertView show];
			// Bring the keyboard back up, because they'll probably need to change something.
			[_usernameField becomeFirstResponder];
		}
	}];
}

- (void)signupClicked:(id)sender
{
    //Transition to the next thing.
    EmailSignupVC *signupVC = [[EmailSignupVC alloc] init];
    signupVC.hidesBottomBarWhenPushed = YES;
    //Set username and password if they entered them.
    
    if(![_usernameField.text isEqualToString:@""])
    {
        signupVC.username = _usernameField.text;
    }
    if(![_passwordField.text isEqualToString:@""])
    {
        signupVC.password = _passwordField.text;
    }
    [self.navigationController pushViewController:signupVC animated:YES];
    
    
}

#pragma mark UITextFielDelegate

- (void)textInputChanged:(NSNotification *)note {
//	doneButton.enabled = [self shouldEnableDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == _usernameField)
    {
		[_passwordField becomeFirstResponder];
	}
	if (textField == _passwordField)
    {
        [_passwordField resignFirstResponder];
	}
    
	return YES;
}

-  (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_usernameField];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_passwordField];
}



-(BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
