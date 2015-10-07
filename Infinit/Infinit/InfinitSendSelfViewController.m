//
//  InfinitSendSelfViewController.m
//  Infinit
//
//  Created by Chris Crone on 06/10/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitSendSelfViewController.h"

#import "InfinitHostDevice.h"
#import "InfinitMetricsManager.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitTabBarController.h"
#import "InfinitUploadThumbnailManager.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitSendSelfViewController () <UIGestureRecognizerDelegate>

@property (nonatomic) IBOutlet UIBarButtonItem* back_button;

@end

@implementation InfinitSendSelfViewController

#pragma mark - Init

- (void)awakeFromNib
{
  [super awakeFromNib];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.back_button.image = [UIImage imageNamed:@"icon-back-white"];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;
  [self.navigationController.interactivePopGestureRecognizer addTarget:self
                                                                action:@selector(backTapped:)];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
  [self.navigationController.interactivePopGestureRecognizer removeTarget:self action:nil];
}

#pragma mark - Button Handling

- (IBAction)deviceTapped:(id)sender
{
  void (^send_block)() = ^()
  {
    InfinitUser* me = [InfinitUserManager sharedInstance].me;
    NSArray* transaction_ids =
      @[[[InfinitStateManager sharedInstance] sendFiles:self.managed_files.sorted_paths
                                            toRecipient:me
                                            withMessage:nil]];
    [[InfinitTemporaryFileManager sharedInstance] addTransactionIds:transaction_ids
                                                    forManagedFiles:self.managed_files];
    [[InfinitTemporaryFileManager sharedInstance] markManagedFilesAsSending:self.managed_files];
    InfinitUploadThumbnailManager* thumb_manager = [InfinitUploadThumbnailManager sharedInstance];
    if (self.managed_files.asset_map.count)
    {
      NSMutableArray* ordered_assets = [NSMutableArray array];
      for (NSString* path in self.managed_files.sorted_paths)
      {
        id asset = [self.managed_files.asset_map allKeysForObject:path].firstObject;
        [ordered_assets addObject:asset];
      }
      [thumb_manager generateThumbnailsForAssets:ordered_assets
                          forTransactionsWithIds:transaction_ids];
    }
    else
    {
      [thumb_manager generateThumbnailsForFiles:self.managed_files.sorted_paths
                         forTransactionsWithIds:transaction_ids];
    }
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewSend
                               method:InfinitUIMethodTap];
    self.managed_files = nil;
  };
  if (self.managed_files.copying)
  {
    self.managed_files.done_copying_block = send_block;
    SEL selector = @selector(showTransactionPreparingNotification);
    if ([self.tabBarController respondsToSelector:selector])
    {
      [self.tabBarController performSelector:selector withObject:nil afterDelay:1.0f];
    }
  }
  else
  {
    send_block();
  }
  [self doneSending];
}

- (void)doneSending
{
  if (self.managed_files && !self.managed_files.sending)
    self.managed_files.sending = YES;
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [((InfinitTabBarController*)self.tabBarController) showMainScreen:self];
  });
}

- (IBAction)backTapped:(id)sender
{
  if (![sender isKindOfClass:UIGestureRecognizer.class])
    [self performSegueWithIdentifier:@"self_only_gallery" sender:sender];
}

- (IBAction)selfImageTapped:(id)sender
{
  [self deviceTapped:sender];
}

- (IBAction)contactsImageTapped:(id)sender
{
  [self performSegueWithIdentifier:@"self_only_send_contact" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"self_only_send_contact"])
  {
    InfinitSendRecipientsController* recipient_controller =
      (InfinitSendRecipientsController*)segue.destinationViewController;
    recipient_controller.managed_files = self.managed_files;
  }
}

@end
