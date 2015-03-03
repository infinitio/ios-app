//
//  InfinitLoginInvitationCodeController.m
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLoginInvitationCodeController.h"

#import "InfinitColor.h"

@interface InfinitLoginInvitationCodeController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity_indicator;
@property (nonatomic, weak) IBOutlet UITextField* code_field;
@property (nonatomic, weak) IBOutlet UILabel* error_label;

@property (nonatomic, weak) IBOutlet UIView* line_1;
@property (nonatomic, weak) IBOutlet UIView* line_2;
@property (nonatomic, weak) IBOutlet UIView* line_3;
@property (nonatomic, weak) IBOutlet UIView* line_4;
@property (nonatomic, weak) IBOutlet UIView* line_5;

@property (nonatomic) NSArray* lines;

@end

static NSDictionary* _attrs = nil;

@implementation InfinitLoginInvitationCodeController

- (void)viewDidLoad
{
  [super viewDidLoad];
  _lines = @[self.line_1, self.line_2, self.line_3, self.line_4, self.line_5];
  [self setLineColor:[InfinitColor colorWithGray:151]];
  if (_attrs == nil)
  {
    _attrs = @{NSFontAttributeName: [UIFont fontWithName:@"Monaco" size:36.0f],
               NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73],
               NSKernAttributeName: @13.0f};
  }
  self.code_field.defaultTextAttributes = _attrs;
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField*)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString*)string
{
  return (textField.text.length < 5 || string.length == 0);
}

- (IBAction)textChanged:(UITextField*)sender
{
  if (sender.text.length == 5)
  {
    // XXX Check code
  }
}

- (IBAction)dismissKeyboard:(UITapGestureRecognizer*)sender
{
  [self.code_field resignFirstResponder];
}

#pragma mark - Button Handling

- (IBAction)skipTapped:(id)sender
{
  [self showHomeScreen];
}

#pragma mark - Helpers

- (void)setLineColor:(UIColor*)color
{
  for (UIView* line in self.lines)
    line.backgroundColor = color;
}

- (void)showHomeScreen
{
  UIStoryboard* storyboard =
  [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
  UIViewController* view_controller =
    [storyboard instantiateViewControllerWithIdentifier:@"tab_bar_controller"];
  [self presentViewController:view_controller animated:YES completion:nil];
}

@end
