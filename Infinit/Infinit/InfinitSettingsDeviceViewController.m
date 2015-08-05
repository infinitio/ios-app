//
//  InfinitSettingsDeviceViewController.m
//  Infinit
//
//  Created by Christopher Crone on 04/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsDeviceViewController.h"

#import "InfinitHostDevice.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitStateManager.h>

@interface InfinitSettingsDeviceViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem* ok_button;
@property (nonatomic, weak) IBOutlet UITextField* name_field;
@property (nonatomic, weak) IBOutlet UIView* name_view;

@property (nonatomic, readonly) NSString* old_name;

@end

@implementation InfinitSettingsDeviceViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  UIColor* nav_color = [InfinitColor colorWithRed:81 green:81 blue:73];
  NSDictionary* nav_title_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                         size:17.0f],
                                    NSForegroundColorAttributeName: nav_color};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_title_attrs];
  NSDictionary* nav_but_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:18.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna]};
  [self.ok_button setTitleTextAttributes:nav_but_attrs forState:UIControlStateNormal];
  self.name_view.layer.borderColor = [InfinitColor colorWithGray:216].CGColor;
  self.name_view.layer.borderWidth = 1.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
  [[InfinitDeviceManager sharedInstance] updateDevices];
  [super viewWillAppear:animated];
  _old_name = [InfinitDeviceManager sharedInstance].this_device.name;
  self.name_field.text = self.old_name;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide)
                                               name:UIKeyboardWillHideNotification 
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

- (void)keyboardWillShow
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return;
  CGFloat delta = -30.0f;
  if (![InfinitHostDevice smallScreen])
    delta -= 30.0f;
  [UIView animateWithDuration:0.2f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.view.transform = CGAffineTransformMakeTranslation(0.0f, delta);
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.view.transform = CGAffineTransformMakeTranslation(0.0f, delta);
     }
   }];
}

- (void)keyboardWillHide
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return;
  [UIView animateWithDuration:0.2f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.view.transform = CGAffineTransformIdentity;
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.view.transform = CGAffineTransformIdentity;
     }
   }];
}

#pragma mark - Button Handling

- (IBAction)okTapped:(id)sender
{
  NSCharacterSet* white_space = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSString* new_name = [self.name_field.text stringByTrimmingCharactersInSet:white_space];
  if (![new_name isEqualToString:self.old_name])
  {
    [[InfinitStateManager sharedInstance] updateDeviceName:new_name
                                                     model:nil 
                                                        os:nil
                                           completionBlock:nil];
  }
  [self performSegueWithIdentifier:@"settings_device_unwind" sender:self];
}

- (IBAction)screenTapped:(id)sender
{
  [self.view endEditing:YES];
}

@end
