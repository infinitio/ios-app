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

@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UITextField* code_field;
@property (nonatomic, weak) IBOutlet InfinitCodeLineView* code_line;
@property (nonatomic, weak) IBOutlet UIButton* skip_button;

@end

static NSDictionary* _attrs = nil;

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
  self.code_field.tintColor = [InfinitColor colorWithRed:91 green:99 blue:106];
  self.code_field.defaultTextAttributes = _attrs;
  self.code_line.error = NO;
  NSMutableAttributedString* info_text = [self.info_label.attributedText mutableCopy];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSTextAlignmentCenter;
  para.lineSpacing = 20.0f;
  [info_text addAttribute:NSParagraphStyleAttributeName
                    value:para
                    range:NSMakeRange(0, info_text.length)];
  self.info_label.attributedText = info_text;
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
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
  if (self.code_field.text.length == 5)
  {
    [self.activity startAnimating];
    self.code_field.enabled = NO;
    [self.code_field resignFirstResponder];
    NSString* code =
      [self.code_field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // XXX check code
    (void)code;
  }
}

#pragma mark - Button Handling

- (IBAction)skipTapped:(id)sender
{
  [self.delegate welcomeCode:self doneWithCode:nil];
}

@end
