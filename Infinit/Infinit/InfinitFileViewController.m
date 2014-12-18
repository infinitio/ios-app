//
//  InfinitFileViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFileViewController.h"

@interface InfinitFileViewController () <UIGestureRecognizerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *fileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeAndDateLabel;

@end

@implementation InfinitFileViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
  self.avatarImageView.layer.borderWidth = 4;
  self.avatarImageView.layer.borderColor = ([[UIColor whiteColor] CGColor]);
  
  UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                  action:@selector(handleLongPress:)];
  self.fileImageView.userInteractionEnabled = YES;
  gestureRecognizer.minimumPressDuration = 0.3;
  gestureRecognizer.delegate = self;
  gestureRecognizer.numberOfTouchesRequired = 1;
  [self.fileImageView addGestureRecognizer:gestureRecognizer];
  
  //title will be the name of the file. Image for a photo.  Sound board for the music.  Static image otherwise (for zip etc...)
  
  
  
  
}
- (IBAction)backButtonSelected:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
  {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save To Camera Roll", @"Share", @"Copy Link", @"Delete", @"More...", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.destructiveButtonIndex = 3;
    [actionSheet showInView:self.tabBarController.view];
  }
}

-(void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  
  
  switch (buttonIndex)
  {
    case 0:
      UIImageWriteToSavedPhotosAlbum(self.fileImageView.image, nil, nil, nil);
      break;
      
    default:
      break;
  }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
