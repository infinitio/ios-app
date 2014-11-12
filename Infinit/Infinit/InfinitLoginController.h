//
//  InfinitLoginController.h
//  Infinit
//
//  Created by Christopher Crone on 23/10/14.
//  Copyright (c) 2014 Christopher Crone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitLoginController : UIViewController <UITextFieldDelegate>

@property (weak) IBOutlet UITextField* email;
@property (weak) IBOutlet UITextField* password;
@property (weak) IBOutlet UIButton* login;
@property (weak) IBOutlet UILabel* error;
@property (weak) IBOutlet UIActivityIndicatorView* spinner;

@end
