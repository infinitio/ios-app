//
//  WelcomeLoginFormView.h
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeLoginFormView : UIView

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* activity;
@property (weak, nonatomic) IBOutlet UIButton* back_button;
@property (weak, nonatomic) IBOutlet UIButton* avatar_button;
@property (weak, nonatomic) IBOutlet UITextField* email_field;
@property (weak, nonatomic) IBOutlet UITextField* password_field;
@property (weak, nonatomic) IBOutlet UIButton* facebook_button;
@property (weak, nonatomic) IBOutlet UIImageView* email_image;
@property (weak, nonatomic) IBOutlet UIImageView* password_image;
@property (weak, nonatomic) IBOutlet UIButton* next_button;
@property (weak, nonatomic) IBOutlet UILabel* error_label;

@property (nonatomic, readonly) CGFloat height;

@end
