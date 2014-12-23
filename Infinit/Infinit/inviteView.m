//
//  inviteView.m
//  Infinit
//
//  Created by Michael Dee on 12/23/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "inviteView.h"

@implementation inviteView

- (void)awakeFromNib
{
  _importPhoneButton.layer.cornerRadius = 2.5f;
  _cancelButton.layer.cornerRadius = 2.5f;
  _findFacebookButton.layer.cornerRadius = 2.5f;
  _findPeopleInfinitButton.layer.cornerRadius = 2.5f;
  
  _importPhoneButton.layer.borderWidth = 1.0f;
  _cancelButton.layer.borderWidth = 1.0f;
  _findFacebookButton.layer.borderWidth = 1.0f;
  _findPeopleInfinitButton.layer.borderWidth = 1.0f;
  
  _importPhoneButton.layer.borderColor = ([[[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  _findPeopleInfinitButton.layer.borderColor = ([[[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  _findFacebookButton.layer.borderColor = ([[[UIColor colorWithRed:42/255.0 green:108/255.0 blue:181/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  _cancelButton.layer.borderColor = ([[UIColor whiteColor] CGColor]);

}

@end
