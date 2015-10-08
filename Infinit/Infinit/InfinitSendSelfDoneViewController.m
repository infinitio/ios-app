//
//  InfinitSendSelfDoneViewController.m
//  Infinit
//
//  Created by Chris Crone on 08/10/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitSendSelfDoneViewController.h"

#import "InfinitTabBarController.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitStateManager.h>

@interface InfinitSendSelfDoneViewController ()

@property (nonatomic) IBOutlet UIActivityIndicatorView* activity_view;
@property (nonatomic) IBOutlet UILabel* email_details;
@property (nonatomic) IBOutlet UIButton* sent_button;

@end

@implementation InfinitSendSelfDoneViewController

#pragma mark - Init

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.sent_button.hidden = YES;
  [self.activity_view startAnimating];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^
  {
    self.sent_button.alpha = 0.0f;
    self.sent_button.hidden = NO;
    [self.activity_view stopAnimating];
    [UIView animateWithDuration:0.3f animations:^
    {
      self.sent_button.alpha = 1.0f;
    }];
  });
  self.navigationController.interactivePopGestureRecognizer.enabled = NO;
  UIColor* email_color = [InfinitColor colorWithRed:91 green:89 blue:74];
  NSString* email = [InfinitStateManager sharedInstance].selfEmail;
  NSString* details_str = [self.email_details.text stringByReplacingOccurrencesOfString:@"<email>"
                                                                             withString:email];
  NSMutableDictionary* attrs =
    [[self.email_details.attributedText attributesAtIndex:0 effectiveRange:NULL] mutableCopy];
  NSMutableAttributedString* details_astr =
    [[NSMutableAttributedString alloc] initWithString:details_str attributes:attrs];
  NSRange email_range = [details_str rangeOfString:email];
  if (email_range.location != NSNotFound)
  {
    [details_astr addAttribute:NSForegroundColorAttributeName value:email_color range:email_range];
    self.email_details.attributedText = details_astr;
  }
}

#pragma mark - Button Handling

- (IBAction)doneTapped:(id)sender
{
  [((InfinitTabBarController*)self.tabBarController) showMainScreen:self];
}

@end
