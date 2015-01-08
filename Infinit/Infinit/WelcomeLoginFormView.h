//
//  WelcomeLoginFormView.h
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeLoginFormView : UIView
@property (weak, nonatomic) IBOutlet UIButton *back_button;
@property (weak, nonatomic) IBOutlet UIButton *avatar_button;
@property (weak, nonatomic) IBOutlet UITextField *login_email_textfield;
@property (weak, nonatomic) IBOutlet UITextField *login_password_textfield;
@property (weak, nonatomic) IBOutlet UIButton *login_facebook_button;
@property (weak, nonatomic) IBOutlet UIImageView *login_email_imageview;
@property (weak, nonatomic) IBOutlet UIImageView *login_password_imageview;
@property (weak, nonatomic) IBOutlet UIButton *next_button;
@property (weak, nonatomic) IBOutlet UILabel *login_error_label;

@end
