//
//  WelcomeSignupFacebookView.h
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeSignupFacebookView : UIView

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* avatar_button;
@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet UIImageView* email_image;
@property (nonatomic, weak) IBOutlet UITextField* email_field;
@property (nonatomic, weak) IBOutlet UIImageView* fullname_image;
@property (nonatomic, weak) IBOutlet UITextField* fullname_field;
@property (nonatomic, weak) IBOutlet UILabel* error_label;
@property (nonatomic, weak) IBOutlet UIButton* legal_button;

@property (nonatomic, readwrite) UIImage* avatar;
@property (nonatomic, readonly) CGFloat height;

@end
