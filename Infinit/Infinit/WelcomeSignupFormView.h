//
//  WelcomeSignupFormView.h
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeSignupFormView : UIView
@property (weak, nonatomic) IBOutlet UIButton* back_button;
@property (weak, nonatomic) IBOutlet UIButton* avatar_button;
@property (weak, nonatomic) IBOutlet UIButton* next_button;
@property (weak, nonatomic) IBOutlet UIImageView* signup_email_imageview;
@property (weak, nonatomic) IBOutlet UITextField* signup_email_textfield;
@property (weak, nonatomic) IBOutlet UIImageView* signup_fullname_imageview;
@property (weak, nonatomic) IBOutlet UITextField* signup_fullname_textifeld;
@property (weak, nonatomic) IBOutlet UIImageView* signup_password_imageview;
@property (weak, nonatomic) IBOutlet UITextField* signup_password_textfield;
@property (weak, nonatomic) IBOutlet UILabel* signup_error_label;

@end
