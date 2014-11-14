//
//  InfinitLoginController.h
//  Infinit
//
//  Created by Christopher Crone on 23/10/14.
//  Copyright (c) 2014 Christopher Crone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitLoginController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField* email;
@property (nonatomic, weak) IBOutlet UITextField* password;
@property (nonatomic, weak) IBOutlet UIButton* login;
@property (nonatomic, weak) IBOutlet UILabel* error;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* spinner;

@end
