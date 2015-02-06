//
//  InfinitSettingsEditProfileViewController.m
//  Infinit
//
//  Created by Christopher Crone on 06/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsEditProfileViewController.h"

#import "InfinitColor.h"
#import "UIImage+Rounded.h"

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

@import MobileCoreServices;

@interface InfinitSettingsEditProfileViewController () <UIActionSheetDelegate,
                                                        UIGestureRecognizerDelegate,
                                                        UIImagePickerControllerDelegate,
                                                        UINavigationControllerDelegate,
                                                        UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* ok_button;
@property (nonatomic, weak) IBOutlet UIButton* avatar_button;
@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UITextField* name_field;
@property (nonatomic, weak) IBOutlet UIView* name_view;

@property (nonatomic, strong, readonly) UIImage* avatar_image;
@property (nonatomic, strong, readonly) UIImagePickerController* picker;
@property (nonatomic, weak) InfinitUser* user;

@end

@implementation InfinitSettingsEditProfileViewController

#pragma mark - Init

- (void)viewDidLoad
{
  NSDictionary* nav_title_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                         size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_title_attrs];
  NSDictionary* nav_but_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:18.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorFromPalette:ColorBurntSienna]};
  [self.ok_button setTitleTextAttributes:nav_but_attrs forState:UIControlStateNormal];
  self.name_view.layer.borderColor = [InfinitColor colorWithGray:216].CGColor;
  self.name_view.layer.borderWidth = 1.0f;
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
  self.user = [InfinitUserManager sharedInstance].me;
  self.name_field.text = self.user.fullname;
  if (self.avatar_image == nil)
    self.avatar_view.image = [self.user.avatar circularMaskOfSize:self.avatar_view.bounds.size];
  [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  _picker = nil;
  _avatar_image = nil;
  [super viewDidDisappear:animated];
}

#pragma mark - Button Handling

- (IBAction)changeAvatarTapped:(id)sender
{
  UIActionSheet* actionSheet =
  [[UIActionSheet alloc] initWithTitle:nil
                              delegate:self
                     cancelButtonTitle:NSLocalizedString(@"Back", nil)
                destructiveButtonTitle:nil
                     otherButtonTitles:NSLocalizedString(@"Take new photo", nil),
   NSLocalizedString(@"Choose a photo...", nil), nil];
  [actionSheet showInView:self.view];
}

- (IBAction)backTapped:(id)sender
{
  [self.navigationController.navigationController popViewControllerAnimated:YES];
}

- (IBAction)okTapped:(id)sender
{
  if (self.avatar_image != nil)
  {
    [[InfinitAvatarManager sharedInstance] setSelfAvatar:self.avatar_image];
  }
  if (![self.name_field.text isEqualToString:self.user.fullname] &&
      self.name_field.text.length >= 3)
  {
    [[InfinitStateManager sharedInstance] setSelfFullname:self.name_field.text
                                          performSelector:nil
                                                 onObject:nil];
    self.user.fullname = [self.name_field.text copy];
  }
  [self.navigationController.navigationController popViewControllerAnimated:YES];
}

- (IBAction)screenTap:(id)sender
{
  [self.name_field resignFirstResponder];
}

#pragma mark - Avatar Picker

- (void)actionSheet:(UIActionSheet*)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSString* choice = [actionSheet buttonTitleAtIndex:buttonIndex];
  if([choice isEqualToString:NSLocalizedString(@"Choose a photo...", nil)])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
  }
  if([choice isEqualToString:NSLocalizedString(@"Take new photo", nil)])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
  }
}

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType
{
  if (self.picker == nil)
    _picker = [[UIImagePickerController alloc] init];
  self.picker.view.tintColor = [UIColor blackColor];
  self.picker.sourceType = sourceType;
  self.picker.mediaTypes = @[(NSString*)kUTTypeImage];
  self.picker.allowsEditing = YES;
  self.picker.delegate = self;
  if (sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  }
  [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  _avatar_image = info[UIImagePickerControllerEditedImage];
  [self dismissViewControllerAnimated:YES completion:nil];
  self.avatar_view.image = [self.avatar_image circularMaskOfSize:self.avatar_view.bounds.size];
  [self.avatar_view setNeedsDisplay];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [self.name_field resignFirstResponder];
  return YES;
}

@end
