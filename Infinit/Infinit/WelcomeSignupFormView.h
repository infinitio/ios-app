//
//  WelcomeSignupFormView.h
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeSignupFormView : UIView

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* avatar_button;
@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet UIImageView* email_image;
@property (nonatomic, weak) IBOutlet UITextField* email_field;
@property (nonatomic, weak) IBOutlet UIImageView* fullname_image;
@property (nonatomic, weak) IBOutlet UITextField* fullname_field;
@property (nonatomic, weak) IBOutlet UIImageView* password_image;
@property (nonatomic, weak) IBOutlet UITextField* password_field;
@property (nonatomic, weak) IBOutlet UILabel* error_label;

@property (nonatomic, readonly) CGFloat height;

- (void)setAvatar:(UIImage*)image;

@end
