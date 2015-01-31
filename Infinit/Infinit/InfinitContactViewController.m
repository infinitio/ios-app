//
//  InfinitContactViewController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactViewController.h"

#import "InfinitColor.h"

#import <Gap/InfinitUserManager.h>

#import "UIImage+Rounded.h"

@interface InfinitContactViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* name_label;
@property (nonatomic, weak) IBOutlet UIButton* send_invite_button;
@property (nonatomic, weak) IBOutlet UIButton* favorite_button;

@end

static UIImage* _favorite_icon = nil;
static UIImage* _infinit_icon = nil;

@implementation InfinitContactViewController

#pragma mark - Init

- (void)viewDidLoad
{
  if (_favorite_icon == nil)
    _favorite_icon = [UIImage imageNamed:@"icon-favorite-big"].circularMask;
  if (_infinit_icon == nil)
    _infinit_icon = [UIImage imageNamed:@"icon-logo-red"].circularMask;
  [super viewDidLoad];

  self.send_invite_button.layer.cornerRadius = self.send_invite_button.bounds.size.height / 2.0f;
  self.favorite_button.layer.cornerRadius = self.favorite_button.bounds.size.height / 2.0f;

  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [self configureView];
}

- (IBAction)backButtonTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureView;
{
  self.navigationItem.title = self.contact.fullname;
  self.avatar_view.image = self.contact.avatar.circularMask;
  if (self.contact.infinit_user == nil)
  {
    self.icon_view.hidden = YES;
  }
  else
  {
    if (self.contact.infinit_user.favorite || self.contact.infinit_user.is_self)
      self.icon_view.image = _favorite_icon;
    else
      self.icon_view.image = _infinit_icon;
    self.icon_view.hidden = NO;
  }
  self.name_label.text = self.contact.fullname;
}

#pragma mark - Button Handling

- (IBAction)sendButtonTapped:(id)sender
{
  // XXX open gallery view
}

- (IBAction)favoriteButtonTapped:(id)sender
{
  UIImage* new_icon;
  if (self.contact.infinit_user.favorite)
    new_icon = _infinit_icon;
  else
    new_icon = _favorite_icon;

  [UIView transitionWithView:self.icon_view
                    duration:0.3f
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^
  {
    self.icon_view.image = new_icon;
  } completion:^(BOOL finished)
  {
    if (!finished)
      self.icon_view.image = new_icon;
  }];
  if (self.contact.infinit_user.favorite)
    [[InfinitUserManager sharedInstance] removeFavorite:self.contact.infinit_user];
  else
    [[InfinitUserManager sharedInstance] addFavorite:self.contact.infinit_user];
}

@end
