//
//  ImportContactsCell.m
//  Infinit
//
//  Created by Michael Dee on 12/23/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "ImportContactsCell.h"

@implementation ImportContactsCell

- (void)awakeFromNib
{
  NSString* stringForCopy = @"Infinit is 2x faster and encrypted";
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:stringForCopy];
  
  [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:17] range:NSMakeRange(0, 10)];
  
  [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Medium" size:17] range:NSMakeRange(11, 9)];
  
  [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:17] range:NSMakeRange(20, 5)];
  [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Medium" size:17] range:NSMakeRange(25, 9)];
  [_lineOneLabel setAttributedText:attributedString];
  
                                                
                
  
  _importPhoneContactsButton.layer.cornerRadius = 2.5f;
  _findPeopleButton.layer.cornerRadius = 2.5f;
  _importFacebookButton.layer.cornerRadius = 2.5f;
  
  _importPhoneContactsButton.layer.borderWidth = 1.0f;
  _findPeopleButton.layer.borderWidth = 1.0f;
  _importFacebookButton.layer.borderWidth = 1.0f;
  
  _importPhoneContactsButton.layer.borderColor = ([[[UIColor colorWithRed:137/255.0 green:137/255.0 blue:137/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  _findPeopleButton.layer.borderColor = ([[[UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  _importFacebookButton.layer.borderColor = ([[[UIColor colorWithRed:42/255.0 green:108/255.0 blue:181/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  
  _importPhoneContactsButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  _findPeopleButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];
  _importFacebookButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14];

  
}



@end
