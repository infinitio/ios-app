//
//  InfinitFileViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFileViewController.h"

@interface InfinitFileViewController ()

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
  
  //title will be the name of the file. Image for a photo.  Sound board for the music.  Static image otherwise (for zip etc...)
  
  
}
- (IBAction)backButtonSelected:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
