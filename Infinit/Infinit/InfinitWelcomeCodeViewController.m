//
//  InfinitWelcomeCodeViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeCodeViewController.h"

#import "InfinitColor.h"
#import "InfinitCodeLineView.h"

#import <Gap/InfinitStateManager.h>

@interface InfinitWelcomeCodeViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UITextField* code_field;
@property (nonatomic, weak) IBOutlet InfinitCodeLineView* code_line;
@property (nonatomic, weak) IBOutlet UIButton* skip_button;

@end

static NSDictionary* _attrs = nil;
static NSDictionary* _placeholder_attrs = nil;

@implementation InfinitWelcomeCodeViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  if (_attrs == nil)
  {
    _attrs = @{NSFontAttributeName: [UIFont fontWithName:@"Monaco" size:36.0f],
               NSForegroundColorAttributeName: [InfinitColor colorWithRed:91 green:99 blue:106],
               NSKernAttributeName: @13.0f};
  }
  if (_placeholder_attrs == nil)
  {
    _placeholder_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"Monaco" size:36.0f],
                           NSForegroundColorAttributeName: [InfinitColor colorWithRed:91
                                                                                green:99
                                                                                 blue:106 
                                                                                alpha:0.15f],
                           NSKernAttributeName: @13.0f};
  }
  self.code_field.tintColor = [InfinitColor colorWithRed:91 green:99 blue:106];
  self.code_field.defaultTextAttributes = _attrs;
  NSAttributedString* placeholder =
    [[NSAttributedString alloc] initWithString:self.code_field.placeholder
                                    attributes:_placeholder_attrs];
  self.code_field.attributedPlaceholder = placeholder;
}

- (void)resetView
{
  self.code_field.text = @"";
  self.code_line.error = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self setInfoText:NSLocalizedString(@"Enter the code from your\nSMS or email invitation.", nil)];
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField*)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString*)string
{
  return (textField.text.length < 5 || string.length == 0);
}

- (IBAction)textChanged:(id)sender
{
  self.code_line.error = NO;
  if (self.code_field.text.length == 5)
  {
    [self.activity startAnimating];
    self.code_field.enabled = NO;
    [self.code_field resignFirstResponder];
    NSString* code =
      [self.code_field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    __weak InfinitWelcomeCodeViewController* weak_self = self;
    [[InfinitStateManager sharedInstance] ghostCodeExists:code
                                          completionBlock:^(InfinitStateResult* result,
                                                            NSString* code,
                                                            BOOL valid)
    {
      if (weak_self == nil)
        return;
      InfinitWelcomeCodeViewController* strong_self = weak_self;
      [strong_self.activity stopAnimating];
      strong_self.code_field.enabled = YES;
      if (valid)
      {
        [strong_self.delegate welcomeCode:strong_self doneWithCode:code];
      }
      else
      {
        [strong_self setInfoText:NSLocalizedString(@"Code is not valid.", nil)];
        strong_self.code_line.error = YES;
        [strong_self shakeField:strong_self.code_field andLine:strong_self.code_line];
      }
    }];
  }
}

#pragma mark - Button Handling

- (IBAction)skipTapped:(id)sender
{
  [self.delegate welcomeCode:self doneWithCode:nil];
}

@end
