//
//  InfinitFileViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFileViewController.h"

@interface InfinitFileViewController () <UIGestureRecognizerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIImageView* file_image_view;
@property (weak, nonatomic) IBOutlet UIImageView* avatar_image_view;
@property (weak, nonatomic) IBOutlet UILabel* sender_label;
@property (weak, nonatomic) IBOutlet UILabel* size_date_label;
@property (weak, nonatomic) IBOutlet UIView* white_border_view;

@end

@implementation InfinitFileViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.avatar_image_view.layer.cornerRadius = self.avatar_image_view.frame.size.width/2;
  self.white_border_view.layer.cornerRadius = self.white_border_view.frame.size.width/2;

  
  UILongPressGestureRecognizer* gestureRecognizer =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleLongPress:)];
  self.file_image_view.userInteractionEnabled = YES;
  gestureRecognizer.minimumPressDuration = 0.3;
  gestureRecognizer.delegate = self;
  gestureRecognizer.numberOfTouchesRequired = 1;
  [self.file_image_view addGestureRecognizer:gestureRecognizer];
  
  //title will be the name of the file. Image for a photo.  Sound board for the music.  Static image otherwise (for zip etc...)
  
  
  
  
}
- (IBAction)backButtonSelected:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
  if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
  {
    UIActionSheet* actionSheet =
      [[UIActionSheet alloc] initWithTitle:nil
                                  delegate:self
                         cancelButtonTitle:@"Cancel"
                    destructiveButtonTitle:nil
                         otherButtonTitles:@"Save To Camera Roll", @"Share", @"Copy Link", @"Delete", @"More...", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.destructiveButtonIndex = 3;
    [actionSheet showInView:self.tabBarController.view];
  }
}

-(void)actionSheet:(UIActionSheet*)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case 0:
      UIImageWriteToSavedPhotosAlbum(self.file_image_view.image, nil, nil, nil);
      break;
    default:
      break;
  }
}

@end
