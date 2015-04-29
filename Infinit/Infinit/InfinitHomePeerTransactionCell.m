//
//  InfinitHomePeerTransactionCell.m
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomePeerTransactionCell.h"

#import "InfinitHostDevice.h"
#import "InfinitFilePreview.h"
#import "InfinitHomeTransactionStatusView.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitHostDevice.h"
#import "InfinitHomePeerTransactionFileCell.h"
#import "InfinitHomePeerTransactionMoreFilesCell.h"
#import "InfinitUploadThumbnailManager.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitTime.h>

#import "UIImage+Rounded.h"

@interface InfinitHomeStatusView : UIView
@end

@interface InfinitHomePeerTransactionCell () <UICollectionViewDataSource,
                                              UICollectionViewDelegate,
                                              UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UIView* top_container;
@property (nonatomic, weak) IBOutlet InfinitHomeAvatarView* avatar_view;
@property (nonatomic, weak) IBOutlet UILabel* other_user_label;
@property (nonatomic, weak) IBOutlet UILabel* files_label;
@property (nonatomic, weak) IBOutlet UILabel* time_label;
@property (nonatomic, weak) IBOutlet InfinitHomeTransactionStatusView* status_view;
@property (nonatomic, weak) IBOutlet UIView* top_line;

@property (nonatomic, weak) IBOutlet UICollectionView* files_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* files_constraint;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* status_constraint;
@property (nonatomic, weak) IBOutlet UIView* status_container;
@property (nonatomic, weak) IBOutlet UILabel* status_label;
@property (nonatomic, weak) IBOutlet UILabel* size_label;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* buttons_constraint;
@property (nonatomic, weak) IBOutlet UIView* button_container;
@property (nonatomic, weak) IBOutlet UIView* bottom_line;
@property (nonatomic, weak) IBOutlet UIButton* left_button;
@property (nonatomic, weak) IBOutlet UIButton* right_button;
@property (nonatomic, weak) IBOutlet UIView* button_separator_line;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* button_separator_constraint;

@property (nonatomic, readonly, weak) id<InfinitHomePeerTransactionCellProtocol> delegate;

@property (nonatomic, weak) InfinitDownloadFolderManager* download_manager;
@property (nonatomic, weak) InfinitFolderModel* folder;

@property (nonatomic, readonly) NSArray* upload_thumbnails;

@end

static NSString* _file_cell_id = @"home_file_cell";
static NSString* _more_files_cell_id = @"home_more_files_cell";

static NSAttributedString* _accept_str = nil;
static NSAttributedString* _cancel_str = nil;
static NSAttributedString* _decline_str = nil;
static NSAttributedString* _open_str = nil;
static NSAttributedString* _pause_str = nil;
static NSAttributedString* _resume_str = nil;
static NSAttributedString* _send_str = nil;

static UIImage* _accept_image = nil;
static UIImage* _cancel_image = nil;
static UIImage* _open_image = nil;
static UIImage* _pause_image = nil;
static UIImage* _send_image = nil;

static CGFloat _status_height = 45.0f;
static CGFloat _button_height = 45.0f;

@implementation InfinitHomePeerTransactionCell

- (void)prepareForReuse
{
  [super prepareForReuse];
  _delegate = nil;
  self.status_view.run_transfer_animation = NO;
  _upload_thumbnails = nil;
  [self setFilesViewHidden:YES];
  [self setStatusViewHidden:YES];
  [self setButtonsHidden:YES];
  [self setLeftButtonHidden:NO];
}

- (void)awakeFromNib
{
  if (![InfinitHostDevice iOS7])
  {
    [self.status_container removeConstraint:self.status_constraint];
    self.status_constraint = [NSLayoutConstraint constraintWithItem:self.status_container
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute 
                                                         multiplier:1.0f
                                                           constant:45.0f];
    self.status_constraint.priority = 999;
    [self.status_container addConstraint:self.status_constraint];
    [self.files_view removeConstraint:self.files_constraint];
  }
  [super awakeFromNib];
  self.translatesAutoresizingMaskIntoConstraints = NO;
  UINib* file_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitHomePeerTransactionFileCell.class) bundle:nil];
  [self.files_view registerNib:file_cell_nib forCellWithReuseIdentifier:_file_cell_id];
  UINib* more_files_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitHomePeerTransactionMoreFilesCell.class)
                   bundle:nil];
  [self.files_view registerNib:more_files_cell_nib forCellWithReuseIdentifier:_more_files_cell_id];
  [self.files_view registerNib:file_cell_nib forCellWithReuseIdentifier:_file_cell_id];
  self.left_button.imageView.contentMode = UIViewContentModeCenter;
  self.left_button.imageEdgeInsets = UIEdgeInsetsMake(2.0f, -3.0f, 0.0f, 0.0f);
  self.left_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -5.0f);
  self.right_button.imageView.contentMode = UIViewContentModeCenter;
  self.right_button.imageEdgeInsets = UIEdgeInsetsMake(2.0f, -3.0f, 0.0f, 0.0f);
  self.right_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -5.0f);

  UIFont* font = [UIFont fontWithName:@"SourceSansPro-Bold" size:15.0f];

  NSDictionary* gray_attrs = nil;
  NSDictionary* green_attrs = nil;
  NSDictionary* red_attrs = nil;

  if (!(_accept_str && _cancel_str && _decline_str && _open_str && _pause_str && _send_str))
  {
    gray_attrs =
      @{NSFontAttributeName: font,
        NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73]};
    green_attrs =
      @{NSFontAttributeName: font,
        NSForegroundColorAttributeName: [InfinitColor colorFromPalette:InfinitPaletteColorShamRock]};
    red_attrs =
      @{NSFontAttributeName: font,
        NSForegroundColorAttributeName: [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna]};
  }

  if (!_accept_str)
  {
    _accept_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ACCEPT", nil)
                                                  attributes:green_attrs];
  }
  if (!_cancel_str)
  {
    _cancel_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"CANCEL", nil)
                                                  attributes:red_attrs];
  }
  if (!_decline_str)
  {
    _decline_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"DECLINE", nil)
                                                   attributes:red_attrs];
  }
  if (!_open_str)
  {
    _open_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"OPEN", nil)
                                                attributes:red_attrs];
  }
  if (!_pause_str)
  {
    _pause_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"PAUSE", nil)
                                                 attributes:gray_attrs];
  }
  if (!_resume_str)
  {
    _resume_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"RESUME", nil)
                                                  attributes:gray_attrs];
  }
  if (!_send_str)
  {
    _send_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"SEND", nil)
                                                attributes:red_attrs];
  }

  if (!_accept_image)
    _accept_image = [UIImage imageNamed:@"icon-accept"];
  if (!_cancel_image)
    _cancel_image = [UIImage imageNamed:@"icon-cancel"];
  if (!_open_image)
    _open_image = [UIImage imageNamed:@"icon-open"];
  if (!_pause_image)
    _pause_image = [UIImage imageNamed:@"icon-pause"];
  if (!_send_image)
    _send_image = [UIImage imageNamed:@"icon-send-home"];
}

- (void)setUpWithDelegate:(id<InfinitHomePeerTransactionCellProtocol>)delegate
              transaction:(InfinitPeerTransaction*)transaction
                 expanded:(BOOL)expanded
                   avatar:(UIImage*)avatar
{
  _delegate = delegate;
  _expanded = expanded;
  _transaction = transaction;
  if (self.download_manager == nil)
    _download_manager = [InfinitDownloadFolderManager sharedInstance];
  _folder = [self.download_manager completedFolderForTransactionMetaId:self.transaction.meta_id];
  [self configureCellLayoutWithShadow:YES];
  [self configureCellStatusView];
  self.avatar_view.image = avatar;
  NSString* other_name = nil;
  if (self.transaction.other_user.is_self)
  {
    InfinitDevice* device = nil;
    if (self.transaction.from_device)
      device = [[InfinitDeviceManager sharedInstance] deviceWithId:transaction.recipient_device];
    else
      device = [[InfinitDeviceManager sharedInstance] deviceWithId:transaction.sender_device_id];

    if (device == nil)
      other_name = NSLocalizedString(@"me", nil);
    else
      other_name = device.name;
  }
  else
  {
    other_name = self.transaction.other_user.fullname;
  }
  if (self.transaction.from_device)
  {
    self.other_user_label.text =
      [NSString stringWithFormat:NSLocalizedString(@"To %@", nil), other_name];
  }
  else
  {
    self.other_user_label.text =
      [NSString stringWithFormat:NSLocalizedString(@"From %@", nil), other_name];
  }
  self.time_label.text = [InfinitTime relativeDateOf:self.transaction.mtime longerFormat:NO];
  if (self.folder && self.folder.files.count > 0)
  {
    if (self.folder.files.count == 1)
    {
      self.files_label.text = [self.folder.files[0] name];
    }
    else
    {
      self.files_label.text = [NSString stringWithFormat:NSLocalizedString(@"%lu files", nil),
                               self.folder.files.count];
    }
  }
  else
  {
    if (self.transaction.files.count == 1)
    {
      self.files_label.text = self.transaction.files[0];
    }
    else
    {
      self.files_label.text = [NSString stringWithFormat:NSLocalizedString(@"%lu files", nil),
                               self.transaction.files.count];
    }
  }
  if (self.transaction.from_device)
  {
    InfinitUploadThumbnailManager* manager = [InfinitUploadThumbnailManager sharedInstance];
    if ([manager areThumbnailsForTransaction:self.transaction])
      _upload_thumbnails = [manager thumbnailsForTransaction:self.transaction];
  }
  self.status_label.text = [self statusString];
  if (self.transaction.size.unsignedIntegerValue == 0)
    self.size_label.text = @"";
  else
    self.size_label.text = [InfinitDataSize fileSizeStringFrom:self.transaction.size];
  [self setProgress];
}

- (void)setButtonsHidden:(BOOL)hidden
{
  self.button_container.hidden = hidden;
  self.buttons_constraint.constant = hidden ? 0.0f : _button_height;
}

- (void)setStatusViewHidden:(BOOL)hidden
{
  self.status_container.hidden = hidden;
  self.status_constraint.constant = hidden ? 0.0f : _status_height;
}

- (void)setFilesViewHidden:(BOOL)hidden
{
  self.top_line.hidden = hidden;
  self.files_view.hidden = hidden;
  self.files_constraint.constant =
    hidden ? 0.0f : self.files_view.collectionViewLayout.collectionViewContentSize.height;
  if (!hidden)
    [self.files_view reloadData];
}

- (void)setLeftButtonHidden:(BOOL)hidden
{
  self.button_separator_constraint.constant = hidden ? (self.bounds.size.width / 2.0f - 1.0f)
                                                     : 0.0f;
  self.button_separator_line.hidden = hidden;
  self.left_button.hidden = hidden;
}

- (void)setPauseCancelButtons
{
  [self.left_button setImage:_pause_image forState:UIControlStateNormal];
  self.left_button.tintColor = [InfinitColor colorWithRed:81 green:81 blue:73];
  if (self.transaction.status == gap_transaction_paused)
    [self.left_button setAttributedTitle:_resume_str forState:UIControlStateNormal];
  else
    [self.left_button setAttributedTitle:_pause_str forState:UIControlStateNormal];
  [self.right_button setImage:_cancel_image forState:UIControlStateNormal];
  self.right_button.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  [self.right_button setAttributedTitle:_cancel_str forState:UIControlStateNormal];
  [self setLeftButtonHidden:YES];
}

- (void)setAcceptRejectButtons
{
  [self.left_button setImage:_accept_image forState:UIControlStateNormal];
  self.right_button.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorShamRock];
  [self.left_button setAttributedTitle:_accept_str forState:UIControlStateNormal];
  [self.right_button setImage:_cancel_image forState:UIControlStateNormal];
  [self.right_button setAttributedTitle:_decline_str forState:UIControlStateNormal];
  self.right_button.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  [self setLeftButtonHidden:NO];
}

- (void)setOpenSendButtons
{
  [self.left_button setImage:_open_image forState:UIControlStateNormal];
  self.left_button.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  [self.left_button setAttributedTitle:_open_str forState:UIControlStateNormal];
  [self.right_button setImage:_send_image forState:UIControlStateNormal];
  self.right_button.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  [self.right_button setAttributedTitle:_send_str forState:UIControlStateNormal];
  [self setLeftButtonHidden:NO];
}

- (void)configureCellLayoutWithShadow:(BOOL)shadow
{
  [self setFilesViewHidden:YES];
  switch (self.transaction.status)
  {
    case gap_transaction_new:
    case gap_transaction_on_other_device:
      if (self.expanded)
        [self setPauseCancelButtons];
      [self setButtonsHidden:!self.expanded];
      self.top_line.hidden = !self.expanded;
      [self setStatusViewHidden:!self.expanded];
      if (self.transaction.from_device && self.expanded)
        [self setFilesViewHidden:NO];
      break;
    case gap_transaction_waiting_accept:
      [self setButtonsHidden:!(self.expanded || self.transaction.receivable)];
      [self setStatusViewHidden:!self.expanded];
      self.top_line.hidden = !self.expanded;
      if (self.transaction.receivable)
      {
        [self setAcceptRejectButtons];
        if (self.expanded)
          [self setFilesViewHidden:NO];
      }
      else if (self.expanded)
      {
        [self setPauseCancelButtons];
      }
      if (self.transaction.from_device && self.expanded)
      {
        [self setFilesViewHidden:NO];
      }
      break;

    case gap_transaction_waiting_data:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    case gap_transaction_paused:
      [self setButtonsHidden:!self.expanded];
      [self setStatusViewHidden:!self.expanded];
      self.top_line.hidden = !self.expanded;
      if (self.expanded)
        [self setPauseCancelButtons];
      if (self.transaction.to_device && self.expanded)
        [self setFilesViewHidden:NO];
      if (self.transaction.from_device && self.expanded)
        [self setFilesViewHidden:NO];
      break;

    case gap_transaction_cloud_buffered:
    case gap_transaction_rejected:
    case gap_transaction_finished:
    case gap_transaction_failed:
    case gap_transaction_canceled:
      [self setButtonsHidden:YES];
      [self setStatusViewHidden:!self.expanded];
      self.top_line.hidden = !self.expanded;
      if (self.transaction.to_device && self.expanded)
      {
         if (self.transaction.status == gap_transaction_finished)
        {
          InfinitDownloadFolderManager* manager = [InfinitDownloadFolderManager sharedInstance];
          InfinitFolderModel* folder =
            [manager completedFolderForTransactionMetaId:self.transaction.meta_id];
          if (folder)
          {
            [self setOpenSendButtons];
            [self setButtonsHidden:NO];
          }
          [self setFilesViewHidden:NO];
        }
      }
      if (self.transaction.from_device && self.expanded)
        [self setFilesViewHidden:NO];
      break;

    default:
      break;
  }
  if (shadow)
  {
    self.layer.shadowPath =
      [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:3.0f].CGPath;
  }
}

- (void)configureCellStatusView
{
  switch (self.transaction.status)
  {
    case gap_transaction_new:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
      self.status_view.run_transfer_animation = YES;
      break;

    case gap_transaction_canceled:
    case gap_transaction_failed:
    case gap_transaction_rejected:
      self.status_view.image = [UIImage imageNamed:@"icon-canceled"];
      break;

    case gap_transaction_cloud_buffered:
      self.status_view.image = [UIImage imageNamed:@"icon-sent"];
      break;

    case gap_transaction_finished:
      self.status_view.image = [UIImage imageNamed:@"icon-received"];
      break;

    default:
      self.status_view.image = nil;
      break;
  }
}

- (void)setExpanded:(BOOL)expanded
{
  if (self.expanded == expanded)
    return;
  _expanded = expanded;
  [self configureCellLayoutWithShadow:YES];
}

- (void)setProgress
{
  float progress = self.transaction.progress;
  if (!self.transaction.done &&
      (progress > 0.0f || self.transaction.status == gap_transaction_transferring))
  {
    self.avatar_view.progress = progress;
    self.avatar_view.enable_progress = YES;
  }
  else
  {
    self.avatar_view.enable_progress = NO;
  }
}

- (NSString*)statusString
{
  switch (self.transaction.status)
  {
    case gap_transaction_new:
      return NSLocalizedString(@"Preparing", nil);
    case gap_transaction_on_other_device:
      return NSLocalizedString(@"Transferring on another device", nil);
    case gap_transaction_waiting_accept:
      if (self.transaction.recipient.is_self && self.transaction.from_device)
      {
        return NSLocalizedString(@"Accept on receiving device", nil);
      }
      else if (self.transaction.receivable)
      {
        return NSLocalizedString(@"Waiting for you to accept", nil);
      }
      else if (self.transaction.sender.is_self)
      {
        return [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to accept", nil),
                self.transaction.recipient.fullname];
      }
    case gap_transaction_waiting_data:
      if (self.transaction.from_device)
      {
        return NSLocalizedString(@"Paused – Check network", nil);
      }
      else if (self.transaction.recipient.is_self && self.transaction.to_device)
      {
        return NSLocalizedString(@"Paused by sending device", nil);
      }
      else if (self.transaction.recipient.is_self)
      {
        return [NSString stringWithFormat:NSLocalizedString(@"Paused by %@", nil),
                self.transaction.sender.fullname];
      }
    case gap_transaction_connecting:
      return NSLocalizedString(@"Connecting", nil);
    case gap_transaction_transferring:
      return NSLocalizedString(@"Transferring", nil);
    case gap_transaction_paused:
      return NSLocalizedString(@"Paused", nil);
    case gap_transaction_cloud_buffered:
      return NSLocalizedString(@"Sent", nil);
    case gap_transaction_canceled:
      if (self.transaction.canceler.is_self)
      {
        return NSLocalizedString(@"Canceled by you", nil);
      }
      else
      {
        if (self.transaction.canceler.fullname.length > 0)
        {
          return [NSString stringWithFormat:NSLocalizedString(@"Canceled by %@", nil),
                  self.transaction.canceler.fullname];
        }
        else
        {
          return NSLocalizedString(@"Canceled", nil);
        }
      }
    case gap_transaction_failed:
      if (self.transaction.recipient.is_self && !self.transaction.sender.is_self)
        return [NSString stringWithFormat:NSLocalizedString(@"Error – %@ must retry", nil),
                self.transaction.sender.fullname];
      else
        return NSLocalizedString(@"Error – Please retry", nil);
    case gap_transaction_finished:
      if (self.transaction.from_device)
        return NSLocalizedString(@"Delivered", nil);
      else if (self.transaction.to_device)
        return NSLocalizedString(@"Received", nil);
      else if (self.transaction.other_user.is_self)
        return NSLocalizedString(@"Received on another device", nil);
      else
        return NSLocalizedString(@"Delivered", nil);
    case gap_transaction_rejected:
      if (!self.transaction.recipient.is_self)
      {
        return [NSString stringWithFormat:NSLocalizedString(@"Canceled by %@", nil),
                self.transaction.other_user.fullname];
      }
      else
      {
        return NSLocalizedString(@"Canceled by you", nil);
      }

    default:
      return @"";
  }
}

- (void)setAvatar:(UIImage*)avatar
{
  self.avatar_view.image = avatar;
}

- (void)pauseAnimations
{
  self.status_view.run_transfer_animation = NO;
}

- (void)updateProgressOverDuration:(NSTimeInterval)duration
{
  if (self.transaction.status != gap_transaction_connecting &&
      self.transaction.status != gap_transaction_transferring)
  {
    return;
  }
  self.status_view.run_transfer_animation = YES;
  [self.avatar_view setProgress:self.transaction.progress withAnimationTime:duration];
}

#pragma mark - Collection View Datasource/Delegate

- (void)collectionView:(UICollectionView*)collectionView
didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.folder != nil)
  {
    if (indexPath.row == 5)
      [self.delegate cellOpenTapped:self];
    else
    [self.delegate cell:self openFileTapped:indexPath.row];
  }
}

- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  if (self.folder)
    return self.folder.files.count > 5 ? 6 : self.folder.files.count;
  else
    return self.transaction.files.count > 5 ? 6 : self.transaction.files.count;
}

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout 
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  return CGSizeMake((self.bounds.size.width / 3.0f) - 10.0f, 75.0f);
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.row == 5)
  {
    InfinitHomePeerTransactionMoreFilesCell* cell =
      [self.files_view dequeueReusableCellWithReuseIdentifier:_more_files_cell_id
                                                 forIndexPath:indexPath];
    if (self.folder)
      cell.count = self.folder.files.count - 5;
    else
      cell.count = self.transaction.files.count - 5;
    return cell;
  }

  InfinitHomePeerTransactionFileCell* cell =
    [self.files_view dequeueReusableCellWithReuseIdentifier:_file_cell_id forIndexPath:indexPath];
  CGSize thumb_size = CGSizeMake(45.0f, 45.0f);
  UIImage* thumb = nil;
  if (self.folder)
  {
    cell.filename = [self.folder.files[indexPath.row] name];
    thumb = [self.folder.files[indexPath.row] thumbnail];
  }
  else if (self.upload_thumbnails)
  {
    cell.filename = self.transaction.files[indexPath.row];
    thumb = self.upload_thumbnails[indexPath.row];
  }
  else
  {
    cell.filename = self.transaction.files[indexPath.row];
    thumb = [InfinitFilePreview iconForFilename:self.transaction.files[indexPath.row]];
  }
  cell.thumbnail = [thumb infinit_roundedMaskOfSize:thumb_size cornerRadius:2.0f];
  return cell;
}

#pragma mark - Button Handling

- (IBAction)leftButtonTapped:(id)sender
{
  switch (self.transaction.status)
  {
    case gap_transaction_waiting_accept:
      if (self.transaction.receivable)
        [self.delegate cellAcceptTapped:self];
      else
        [self.delegate cellPauseTapped:self];
      break;

    case gap_transaction_new:
      // Can only be sender.
    case gap_transaction_on_other_device:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    case gap_transaction_paused:
    case gap_transaction_waiting_data:
    case gap_transaction_cloud_buffered:
      [self.delegate cellPauseTapped:self];
      break;

    case gap_transaction_finished:
      [self.delegate cellOpenTapped:self];

    default:
      break;
  }
}

- (IBAction)rightButtonTapped:(id)sender
{
  switch (self.transaction.status)
  {
    case gap_transaction_waiting_accept:
      if (self.transaction.receivable)
        [self.delegate cellRejectTapped:self];
      else
        [self.delegate cellCancelTapped:self];
      break;

    case gap_transaction_new:
      // Can only be sender.
    case gap_transaction_on_other_device:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    case gap_transaction_paused:
    case gap_transaction_waiting_data:
    case gap_transaction_cloud_buffered:
      [self.delegate cellCancelTapped:self];
      break;

    case gap_transaction_finished:
      [self.delegate cellSendTapped:self];

    default:
      break;
  }
}

@end
