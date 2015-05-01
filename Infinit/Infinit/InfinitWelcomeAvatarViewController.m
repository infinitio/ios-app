//
//  InfinitWelcomeAvatarViewController.m
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeAvatarViewController.h"

#import "UIImage+Rounded.h"

#import <Gap/InfinitColor.h>

@import MobileCoreServices;

@interface InfinitWelcomeAvatarViewController () <UIActionSheetDelegate,
                                                  UIImagePickerControllerDelegate,
                                                  UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton* avatar_button;
@property (nonatomic, weak) IBOutlet UIButton* next_button;

@property (nonatomic, readonly) UIImage* avatar;
@property (nonatomic, strong) UIImagePickerController* image_picker;

@end

static CGSize _avatar_size = {500.0f, 500.0f};

@implementation InfinitWelcomeAvatarViewController

- (void)resetView
{
  [super resetView];
  _avatar = nil;
  [self.next_button setTitle:NSLocalizedString(@"Skip", nil) forState:UIControlStateNormal];
  [self.avatar_button setImage:[UIImage imageNamed:@"icon-photo"] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.avatar_button.layer.cornerRadius = floor(self.avatar_button.bounds.size.height / 2.0f);
  self.avatar_button.layer.borderColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorLoginBlack].CGColor;
  self.avatar_button.layer.borderWidth = 2.0f;
  self.avatar_button.layer.masksToBounds = YES;
}

#pragma mark - Button Handling

- (IBAction)avatarTapped:(id)sender
{
  NSString* clear_avatar = nil;
  if (self.avatar)
    clear_avatar = NSLocalizedString(@"Clear avatar", nil);
  UIActionSheet* sheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                  destructiveButtonTitle:clear_avatar
                       otherButtonTitles:NSLocalizedString(@"Take a new photo", nil),
                                         NSLocalizedString(@"Choose a photo", nil), nil];
  [sheet showInView:self.view.superview];
}

- (void)actionSheet:(UIActionSheet*)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet.cancelButtonIndex == buttonIndex)
  {
    [self.image_picker dismissViewControllerAnimated:YES completion:NULL];
  }
  else if (actionSheet.destructiveButtonIndex == buttonIndex)
  {
    [UIView animateWithDuration:0.2f animations:^
    {
      self.avatar_button.alpha = 0.0f;
      [self.next_button setTitle:NSLocalizedString(@"Skip", nil) forState:UIControlStateNormal];
    } completion:^(BOOL finished)
    {
      [self.avatar_button setImage:[UIImage imageNamed:@"icon-photo"]
                          forState:UIControlStateNormal];
      [UIView animateWithDuration:0.2f animations:^
      {
        self.avatar_button.alpha = 1.0f;
      }];
    }];
    _avatar = nil;
  }
  else if (actionSheet.firstOtherButtonIndex == buttonIndex)
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
  }
  else if (actionSheet.firstOtherButtonIndex + 1 == buttonIndex)
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
  }
}

- (IBAction)nextTapped:(id)sender
{
  [self.delegate welcomeAvatarDone:self withAvatar:self.avatar];
  _image_picker = nil;
}

#pragma mark - Image Picker

- (void)presentImagePicker:(UIImagePickerControllerSourceType)source
{
  if (self.image_picker == nil)
  {
    self.image_picker = [[UIImagePickerController alloc] init];
    self.image_picker.view.tintColor = [UIColor blackColor];
    self.image_picker.mediaTypes = @[(NSString*)kUTTypeImage];
    self.image_picker.allowsEditing = YES;
    self.image_picker.delegate = self;
  }
  self.image_picker.sourceType = source;
  if (source == UIImagePickerControllerSourceTypeCamera)
    self.image_picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  [self presentViewController:self.image_picker animated:YES completion:nil];
}

#pragma mark - Image Picker Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  _avatar = [self squareCropAndResizeImage:info[UIImagePickerControllerEditedImage]];
  UIImage* round_image = [self.avatar infinit_circularMaskOfSize:self.avatar_button.bounds.size];
  [self.avatar_button setImage:round_image forState:UIControlStateNormal];
  [self.next_button setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
  [self.image_picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helpers

- (UIImage*)squareCropAndResizeImage:(UIImage*)image
{
  CGFloat scale = MIN(CGImageGetWidth(image.CGImage) / _avatar_size.width,
                      CGImageGetHeight(image.CGImage) / _avatar_size.height);
  CGSize new_size = CGSizeMake(floor(image.size.width / scale), floor(image.size.height / scale));
  UIGraphicsBeginImageContext(_avatar_size);
  CGRect rect = CGRectMake(0.0f, 0.0f, new_size.width, new_size.height);
  CGRect clip_rect = CGRectMake(floor((_avatar_size.width - new_size.width) / 2.0f),
                                floor((_avatar_size.height - new_size.height) / 2.0f),
                                new_size.width,
                                new_size.height);
  UIRectClip(clip_rect);
  [image drawInRect:rect];
  UIImage* res = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return res;
}

@end
