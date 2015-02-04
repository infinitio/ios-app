//
//  InfinitSendToSelfOverlayView.m
//  Infinit
//
//  Created by Christopher Crone on 03/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendToSelfOverlayView.h"

#import "InfinitHostDevice.h"

@interface InfinitSendToSelfOverlayView ()

@property (nonatomic, weak) IBOutlet UILabel* header_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UIImageView* first_image;
@property (nonatomic, weak) IBOutlet UIView* second_image;
@property (nonatomic, weak) IBOutlet UIButton* next_button;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* first_image_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* second_image_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_constraint;

@end

@implementation InfinitSendToSelfOverlayView

- (void)awakeFromNib
{
  self.next_button.layer.cornerRadius = self.next_button.bounds.size.height / 2.0f;
  self.send_email_button.layer.cornerRadius = self.send_email_button.bounds.size.height / 2.0f;
  self.already_infinit_button.layer.cornerRadius =
    self.already_infinit_button.bounds.size.height / 2.0f;
  self.already_infinit_button.layer.borderColor = [UIColor whiteColor].CGColor;
  self.already_infinit_button.layer.borderWidth = 1.0f;
  if ([InfinitHostDevice smallScreen])
  {
    self.top_constraint.constant -= 22.0f;
    self.first_image_constraint.constant -= 25.0f;
    self.second_image_constraint.constant -= 30.0f;
  }
}

- (IBAction)nextTapped:(id)sender
{
  self.next_button.hidden = YES;
  self.send_email_button.hidden = NO;
  self.already_infinit_button.hidden = NO;
  self.header_label.text = NSLocalizedString(@"Install Infinit for\nMac or Windows!", nil);
  self.info_label.text = NSLocalizedString(@"Visit infinit.io on your computer to\ndownload.", nil);
  self.info_label.numberOfLines = 2;
  self.first_image.hidden = YES;
  self.second_image.hidden = NO;
}

@end
