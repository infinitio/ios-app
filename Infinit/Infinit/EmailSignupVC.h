//
//  EmailSignupVC.h
//  Parlae
//
//  Created by Michael Dee on 8/15/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailSignupVC : UIViewController

@property (strong, nonatomic)  UITextField *emailField;
@property (strong, nonatomic)  UITextField *usernameField;
@property (strong, nonatomic)  UITextField *passwordField;
@property (strong, nonatomic)  UIButton *backButton;
@property (strong, nonatomic)  UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;



@end
