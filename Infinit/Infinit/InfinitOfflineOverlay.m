//
//  InfinitOfflineOverlay.m
//  Infinit
//
//  Created by Christopher Crone on 17/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitOfflineOverlay.h"

#import "InfinitTabBarController.h"

#import "InfinitColor.h"

@interface InfinitOfflineOverlay ()

@property (nonatomic, weak) IBOutlet UIButton* files_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_constraint;
@property (nonatomic, weak) IBOutlet UILabel* warning_label;
@property (nonatomic, weak) IBOutlet UIImageView* warning_icon;

@end

@implementation InfinitOfflineOverlay

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _dark = NO;
  }
  return self;
}

- (void)awakeFromNib
{
  self.files_button.layer.cornerRadius = self.files_button.bounds.size.height / 2.0f;
  self.files_button.hidden = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (IBAction)filesTapped:(id)sender
{
  [self.delegate offlineOverlayfilesButtonTapped:self];
}

- (void)setDark:(BOOL)dark
{
  if (self.dark == dark)
    return;
  _dark = dark;
  if (self.dark)
  {
    self.backgroundColor = [InfinitColor colorFromPalette:InfinitPaletteColorSendBlack];
    self.warning_icon.image = [UIImage imageNamed:@"icon-warning-white"];
    self.warning_label.textColor = [UIColor whiteColor];
    self.files_button.backgroundColor = [UIColor whiteColor];
    [self.files_button setTitleColor:[InfinitColor colorFromPalette:InfinitPaletteColorSendBlack]
                            forState:UIControlStateNormal];
  }
  else
  {
    self.backgroundColor = [InfinitColor colorFromPalette:InfinitPaletteColorLightGray];
    self.warning_icon.image = [UIImage imageNamed:@"icon-warning"];
    self.warning_label.textColor = [InfinitColor colorWithGray:175];
    self.files_button.backgroundColor =
      [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
    [self.files_button setTitleColor:[UIColor whiteColor]
                            forState:UIControlStateNormal];
  }
}

@end
