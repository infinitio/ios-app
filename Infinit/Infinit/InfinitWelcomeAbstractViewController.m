//
//  InfinitWelcomeAbstractViewController.m
//  Infinit
//
//  Created by Christopher Crone on 24/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeAbstractViewController.h"

#import "InfinitColor.h"

@interface InfinitWelcomeAbstractViewController ()

@property (nonatomic, readonly) NSAttributedString* original_info;

@end

@implementation InfinitWelcomeAbstractViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  NSMutableAttributedString* info_text = [self.info_label.attributedText mutableCopy];
  [info_text addAttribute:NSParagraphStyleAttributeName
                    value:self.spaced_style
                    range:NSMakeRange(0, info_text.length)];
  self.info_label.attributedText = info_text;
  _original_info = [self.info_label.attributedText copy];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
}

#pragma mark - General

- (void)shakeField:(UITextField*)field
           andLine:(UIView*)line
{
  CGAffineTransform initial = CGAffineTransformMakeTranslation(-50.0f, 0.0f);
  field.transform = initial;
  line.transform = initial;
  [UIView animateWithDuration:1.0f
                        delay:0.0f
       usingSpringWithDamping:0.2f
        initialSpringVelocity:50.0f
                      options:0
                   animations:^
   {
     field.transform = CGAffineTransformIdentity;
     line.transform = CGAffineTransformIdentity;
   } completion:NULL];
}

- (void)resetView
{
  self.info_label.attributedText = self.original_info;
}

#pragma mark - Helpers

- (UIColor*)normal_color
{
  return [InfinitColor colorFromPalette:InfinitPaletteColorLoginBlack];
}

- (UIColor*)error_color
{
  return [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
}

- (NSParagraphStyle*)spaced_style
{
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSTextAlignmentCenter;
  para.lineSpacing = 20.0f;
  return para;
}

@end
