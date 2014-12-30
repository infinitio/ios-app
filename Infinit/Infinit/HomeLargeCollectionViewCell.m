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
  _filesLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:36];
  
  _imageView.layer.cornerRadius = _imageView.frame.size.height/2;
  
  _blurImageView.image = [self blurWithCoreImage:_blurImageView.image];
  
}

- (UIImage *)blurWithCoreImage:(UIImage *)sourceImage
{
  
  CIImage *imageToBlur = [CIImage imageWithCGImage:sourceImage.CGImage];
  CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
  [gaussianBlurFilter setValue:imageToBlur forKey: @"inputImage"];
  [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 10] forKey: @"inputRadius"];
  CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
  UIImage *endImage = [[UIImage alloc] initWithCIImage:resultImage];
  
  return endImage;
  
}

@end
