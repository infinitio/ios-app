//
//  InfinitInvitationOverlayViewController.m
//  Infinit
//
//  Created by Christopher Crone on 12/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInvitationOverlayViewController.h"

#import "InfinitInvitationOverlayTableViewCell.h"
#import "InfinitHostDevice.h"

@interface InfinitInvitationOverlayViewController () <UITableViewDataSource,
                                                      UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity_indicator;
@property (nonatomic, weak) IBOutlet UIButton* cancel_button;
@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* table_height_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* table_bottom_constraint;
@property (nonatomic, weak) IBOutlet UIButton* whatsapp_button;

@end

static NSString* _cell_id = @"invitation_overlay_cell_id";

@implementation InfinitInvitationOverlayViewController

@synthesize loading = _loading;

- (instancetype)init
{
  NSString* class_name = NSStringFromClass(InfinitInvitationOverlayViewController.class);
  if (self = [super initWithNibName:class_name bundle:nil])
  {}
  return self;
}

- (void)loadView
{
  [super loadView];
  UINib* nib = [UINib nibWithNibName:NSStringFromClass(InfinitInvitationOverlayTableViewCell.class)
                              bundle:nil];
  [self.table_view registerNib:nib forCellReuseIdentifier:_cell_id];
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.cancel_button.layer.cornerRadius = floor(self.cancel_button.bounds.size.height / 2.0f);
  self.cancel_button.layer.borderWidth = 2.0f;
  self.cancel_button.layer.borderColor = [UIColor whiteColor].CGColor;
  self.cancel_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.cancel_button.titleLabel.minimumScaleFactor = 0.5f;
  self.whatsapp_button.layer.cornerRadius = floor(self.whatsapp_button.bounds.size.height / 2.0f);
  self.whatsapp_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.whatsapp_button.titleLabel.minimumScaleFactor = 0.5f;
  self.table_view.allowsSelection = NO;
  self.table_view.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.table_view.alwaysBounceVertical = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.table_view reloadData];
  self.table_height_constraint.constant =
    self.table_view.rowHeight * [self.table_view numberOfRowsInSection:0] + 7.5f;
  if (![InfinitHostDevice canSendWhatsApp] || !self.contact.phone_numbers.count)
  {
    self.whatsapp_button.hidden = YES;
    self.table_bottom_constraint.constant = -(self.whatsapp_button.bounds.size.height + 15.0f);
  }
  [self setButtonsEnabled:YES];
}

#pragma mark - General

- (BOOL)loading
{
  @synchronized(self)
  {
    return _loading;
  }
}

- (void)setLoading:(BOOL)loading
{
  @synchronized(self)
  {
    _loading = loading;
    if (loading)
      [self.activity_indicator startAnimating];
    else
      [self.activity_indicator stopAnimating];
    self.cancel_button.hidden = loading;
    self.whatsapp_button.hidden = ![InfinitHostDevice canSendWhatsApp] || loading;
    self.table_view.hidden = loading;
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.contact.phone_numbers.count + self.contact.emails.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitInvitationOverlayTableViewCell* cell =
    [self.table_view dequeueReusableCellWithIdentifier:_cell_id forIndexPath:indexPath];
  if (indexPath.row < self.contact.phone_numbers.count) // phone number
  {
    [cell setupWithPhoneNumber:self.contact.phone_numbers[indexPath.row]];
  }
  else // email
  {
    NSUInteger index = indexPath.row - self.contact.phone_numbers.count;
    [cell setupWithEmail:self.contact.emails[index]];
  }
  [cell.button addTarget:self
                  action:@selector(recipientSelected:)
        forControlEvents:UIControlEventTouchUpInside];
  return cell;
}

#pragma mark - Button Handling

- (void)recipientSelected:(id)sender
{
  InfinitInvitationOverlayTableViewCell* cell =
    (InfinitInvitationOverlayTableViewCell*)[sender superview].superview;
  InfinitMessageMethod method = InfinitMessageNative;
  if (cell.email)
  {
    method = InfinitMessageEmail;
    self.contact.selected_email_index =
      [self.table_view indexPathForCell:cell].row - self.contact.phone_numbers.count;
  }
  else if (cell.phone)
  {
    method = InfinitMessageNative;
    self.contact.selected_phone_index = [self.table_view indexPathForCell:cell].row;
  }
  InfinitMessagingRecipient* recipient =
    [InfinitMessagingRecipient recipient:self.contact withMethod:method];
  [self setButtonsEnabled:NO];
  [self.delegate invitationOverlay:self gotRecipient:recipient];
}

- (IBAction)cancelTapped:(id)sender
{
  [self.delegate invitationOverlayGotCancel:self];
}

- (IBAction)whatsAppTapped:(id)sender
{
  InfinitMessagingRecipient* recipient =
    [InfinitMessagingRecipient recipient:self.contact
                              withMethod:InfinitMessageWhatsApp];
  [self setButtonsEnabled:NO];
  [self.delegate invitationOverlay:self gotRecipient:recipient];
}

#pragma mark - Helpers

- (void)setButtonsEnabled:(BOOL)enabled
{
  self.cancel_button.enabled = enabled;
  for (NSUInteger row = 0; row < [self.table_view numberOfRowsInSection:0]; row++)
  {
    NSIndexPath* index = [NSIndexPath indexPathForRow:row inSection:0];
    InfinitInvitationOverlayTableViewCell* cell =
      (InfinitInvitationOverlayTableViewCell*)[self.table_view cellForRowAtIndexPath:index];
    cell.button.enabled = enabled;
  }
}

@end
