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

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* image_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_constraint;

@end

@implementation InfinitSendToSelfOverlayView

- (void)awakeFromNib
{
  self.send_email_button.layer.cornerRadius = self.send_email_button.bounds.size.height / 2.0f;
  if ([InfinitHostDevice smallScreen])
  {
    self.top_constraint.constant -= 22.0f;
    self.image_constraint.constant -= 25.0f;
  }
}

@end
