//
//  HomeLargeCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "HomeLargeCollectionViewCell.h"

@implementation HomeLargeCollectionViewCell

- (void)awakeFromNib
{
  self.files_label.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:36];
  self.image_view.layer.cornerRadius = self.image_view.frame.size.height/2;
  self.blur_image_view.image = [self blurWithCoreImage:self.blur_image_view.image];
}

- (void)prepareForReuse
{
  self.files_label.text = nil;
  self.notification_label.text = nil;
  self.self.image_view.image = nil;
  self.self.blur_image_view.image = nil;
}

- (UIImage*)blurWithCoreImage:(UIImage*)sourceImage
{
  CIImage* imageToBlur =
    [CIImage imageWithCGImage:sourceImage.CGImage];
  CIFilter* gaussianBlurFilter =
    [CIFilter filterWithName: @"CIGaussianBlur"];
  [gaussianBlurFilter setValue:imageToBlur
                        forKey: @"inputImage"];
  [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 10]
                        forKey: @"inputRadius"];
  CIImage* resultImage =
    [gaussianBlurFilter valueForKey: @"outputImage"];
  UIImage* endImage =
    [[UIImage alloc] initWithCIImage:resultImage];
  return endImage;
}

- (void)setUpWithTransaction:(InfinitPeerTransaction*)transaction
{
  NSString *files_text = [[NSString alloc] init];
  if(transaction.files.count == 1)
  {
    files_text = [NSString stringWithFormat:@"%lu file", (unsigned long)transaction.files.count];
  }
  else
  {
    files_text = [NSString stringWithFormat:@"%lu files", (unsigned long)transaction.files.count];
  }
  
  self.files_label.text = files_text;
  self.notification_label.text = [NSString stringWithFormat:@"%@ wants to send you %@.",transaction.sender.fullname, files_text];
}

@end
