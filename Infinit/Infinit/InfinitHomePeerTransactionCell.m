//
//  InfinitHomePeerTransactionCell.m
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomePeerTransactionCell.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

#import <Gap/InfinitTime.h>
#import <Gap/InfinitDataSize.h>

#import "UIImage+ImageEffects.h"

static NSDictionary* _norm_attrs = nil;
static NSDictionary* _bold_attrs = nil;
static UIImage* _mask_image = nil;

@interface InfinitHomePeerTransactionCell ()

@property (nonatomic, readonly) id<InfinitHomePeerTransactionCellProtocol> delegate;
@property (nonatomic, readwrite) BOOL dim;
@property (nonatomic, readonly) UIView* blur_view;
@property (nonatomic, readonly) UIView* dark_view;

@end

@implementation InfinitHomePeerTransactionCell

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    [self configureButtons];
    if (_norm_attrs == nil)
    {
      _norm_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0f],
                      NSForegroundColorAttributeName: [UIColor whiteColor]};
    }
    if (_bold_attrs == nil)
    {
      _bold_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0f],
                      NSForegroundColorAttributeName: [UIColor whiteColor]};
    }
  }
  return self;
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.dim = NO;
  self.accept_shown = NO;
  self.cancel_shown = NO;
  _delegate = nil;
  self.status_view.hidden = YES;
}

- (void)layoutSubviews
{
  if (self.blur_view != nil && !CGRectEqualToRect(self.blur_view.frame, self.bounds))
  {
    self.blur_view.frame = self.bounds;
  }
  if (self.dark_view.frame.size.width != self.bounds.size.width)
  {
    CGRect dark_rect = self.dark_view.frame;
    dark_rect.size.width = self.bounds.size.width;
    self.dark_view.frame = dark_rect;
  }
  [super layoutSubviews];
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  if ([UIVisualEffectView class])
  {
    self.background_view.layer.rasterizationScale = [InfinitHostDevice screenScale];
    self.background_view.layer.shouldRasterize = YES;
    if ([InfinitHostDevice deviceCPU] >= InfinitCPUType_ARM64_v8)
    {
      self.background_view.layer.cornerRadius = 3.0f;
      self.background_view.layer.masksToBounds = YES;
    }
    UIBlurEffect* blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _blur_view = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.blur_view.frame = self.bounds;
    [self.background_view addSubview:self.blur_view];
  }
  UITapGestureRecognizer* tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(avatarTapped:)];
  [self.avatar_view addGestureRecognizer:tap];
  CGRect dark_frame = CGRectMake(0.0f, self.bounds.size.height - 58.0f,
                                 self.bounds.size.width, 58.0f);
  _dark_view = [[UIView alloc] initWithFrame:dark_frame];
  self.dark_view.backgroundColor = [InfinitColor colorWithGray:0 alpha:0.19f];
  [self.background_view addSubview:self.dark_view];
}

- (void)configureButtons
{
  self.accept_button.transform = CGAffineTransformMakeRotation(M_PI);
  self.accept_button.adjustsImageWhenDisabled = NO;
  self.accept_container.hidden = YES;
  self.cancel_button.adjustsImageWhenDisabled = NO;
  self.cancel_container.hidden = YES;
}

- (void)setUpWithDelegate:(id<InfinitHomePeerTransactionCellProtocol>)delegate
              transaction:(InfinitPeerTransaction*)transaction
{
  _delegate = delegate;
  InfinitPeerTransaction* old_transaction = _transaction;
  _transaction = transaction;
  if (![old_transaction.other_user isEqual:transaction.other_user])
  {
    [self setBackgroundImage];
    [self updateAvatar];
  }
  [self updateTimeString];
  [self setInfoString];
  [self setProgress];
  [self setStatusImage];
  self.size_label.text = [InfinitDataSize fileSizeStringFrom:transaction.size];
  if (transaction.receivable)
  {
    [self setAcceptShown:YES withAnimation:YES];
    [self setCancelShown:YES withAnimation:YES];
  }
}

- (void)setProgress
{
  float progress = self.transaction.progress;
  if (!self.transaction.done && (progress > 0.0f || self.transaction.status == gap_transaction_transferring))
  {
    self.avatar_view.progress = progress;
    self.avatar_view.enable_progress = YES;
  }
  else
  {
    self.avatar_view.enable_progress = NO;
  }
}

- (void)setStatusImage
{
  UIImage* res = nil;
  switch (self.transaction.status)
  {
    case gap_transaction_canceled:
    case gap_transaction_failed:
    case gap_transaction_rejected:
      res = [UIImage imageNamed:@"icon-rejected"];
      break;

    case gap_transaction_finished:
      res = [UIImage imageNamed:@"icon-checked"];
      break;

    default:
      self.status_view.hidden = YES;
      self.dim = NO;
      return;
  }
  self.dim = YES;
  self.status_view.image = res;
  self.status_view.hidden = NO;
}

- (void)setDim:(BOOL)dim
{
  self.avatar_view.dim_avatar = dim;
  self.info_label.alpha = dim ? 0.5f : 1.0f;
  self.cancel_container.hidden = dim;
  self.accept_container.hidden = dim;
}

- (void)setBackgroundImage
{
  if (![UIVisualEffectView class])
  {
    CGRect image_rect = self.background_view.bounds;
    UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);
    [[UIColor blackColor] set];
    [[UIBezierPath bezierPathWithRoundedRect:image_rect cornerRadius:3.0f] addClip];
    [[self.transaction.other_user.avatar applyDarkEffect] drawInRect:image_rect];
    UIImage* background_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.background_view.image = background_image;
  }
  else
  {
    self.background_view.image = self.transaction.other_user.avatar;
  }
}

- (void)setInfoString
{
  NSString* res = nil;
  NSRange bold_range = NSMakeRange(0, 0);
  NSString* file_count;
  if (self.transaction.files.count == 1)
  {
    file_count = [NSString stringWithFormat:NSLocalizedString(@"%@ file", nil),
                  @(self.transaction.files.count)];
  }
  else
  {
    file_count = [NSString stringWithFormat:NSLocalizedString(@"%@ files", nil),
                  @(self.transaction.files.count)];
  }
  NSString* other_name = self.transaction.other_user.fullname;
  switch (self.transaction.status)
  {
    case gap_transaction_new:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    {
      if (self.transaction.from_device)
      {
        if (self.transaction.other_user.is_self)
        {
          res = [NSString stringWithFormat:NSLocalizedString(@"Sending %@ to yourself...", nil),
                 file_count, other_name];
        }
        else
        {
          res = [NSString stringWithFormat:NSLocalizedString(@"Sending %@ to %@...", nil),
                 file_count, other_name];
        }
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Receiving %@ from %@...", nil),
               file_count, other_name];
      }
      break;
    }
    case gap_transaction_on_other_device:
      res = NSLocalizedString(@"Transferring on another device", nil);
      break;
    case gap_transaction_waiting_accept:
      if (self.transaction.from_device)
      {
        if (self.transaction.other_user.is_self)
        {
          res = [NSString stringWithFormat:NSLocalizedString(@"Waiting for you to accept on another device", nil)];
        }
        else
        {
          res = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to accept %@", nil),
                 other_name, file_count];
        }
      }
      else
      {
        if (self.transaction.other_user.is_self)
        {
          res = [NSString stringWithFormat:NSLocalizedString(@"Accept to receive your %@", nil),
                 file_count];
        }
        else
        {
          res = [NSString stringWithFormat:NSLocalizedString(@"%@ would like to share %@", nil),
                 other_name.capitalizedString, file_count];
        }
      }
      break;
    case gap_transaction_waiting_data:
      if (self.transaction.other_user.is_self)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Waiting for your other device to be online", nil)];
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to be online", nil),
               other_name];
      }
      break;
    case gap_transaction_cloud_buffered:
      if (self.transaction.other_user.is_self)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Uploaded %@, waiting for you to download on another device", nil),
               file_count];
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Uploaded %@, waiting for %@ to download", nil),
               file_count, other_name];
      }
      break;
    case gap_transaction_finished:
      if (self.transaction.from_device)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Sent %@ to another device", nil),
               file_count];
      }
      else if (self.transaction.other_user.is_self)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Received %@ from another device", nil),
               file_count];
      }
      else if (self.transaction.sender.is_self)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Sent %@ to %@", nil),
               file_count, other_name];
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Received %@ from %@", nil),
               file_count, other_name];
      }
      break;
    case gap_transaction_failed:
      res = NSLocalizedString(@"Transfer stopped, please try again", nil);
      break;
    case gap_transaction_canceled:
      res = NSLocalizedString(@"Transfer canceled", nil);
      break;
    case gap_transaction_rejected:
      if (self.transaction.sender.is_self)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"%@ declined the transfer", nil),
               other_name.capitalizedString];
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"You declined the transfer", nil)];
      }
      break;
    case gap_transaction_paused:
      res = [NSString stringWithFormat:NSLocalizedString(@"Transfer of %@ with %@ paused", nil),
             file_count, other_name];
      break;

    case gap_transaction_deleted:
      break;

    default:
      break;
  }
  NSMutableAttributedString* attributed_res =
    [[NSMutableAttributedString alloc] initWithString:res
                                           attributes:_norm_attrs];
  bold_range = [res rangeOfString:file_count];
  if (bold_range.location != NSNotFound)
    [attributed_res setAttributes:_bold_attrs range:bold_range];
  self.info_label.attributedText = attributed_res;
}

- (void)updateAvatar
{
  self.avatar_view.image = self.transaction.other_user.avatar;
  [self setBackgroundImage];
}

- (void)updateProgressOverDuration:(NSTimeInterval)duration
{
  [self updateTimeString];
  [self.avatar_view setProgress:self.transaction.progress withAnimationTime:duration];
}

- (void)updateTimeString
{
  NSString* label_text = nil;
  switch (self.transaction.status)
  {
    case gap_transaction_transferring:
      label_text = [InfinitTime timeRemainingFrom:self.transaction.time_remaining];
      break;

    default:
      label_text = [InfinitTime relativeDateOf:self.transaction.mtime longerFormat:YES];
      break;
  }
  self.time_label.text = label_text;
}

#pragma mark - Button Handling

- (void)avatarTapped:(id)sender
{
  if (self.transaction.done || self.transaction.receivable)
    return;
  [self setCancelShown:!self.cancel_shown withAnimation:YES];
}

- (void)setCancel_shown:(BOOL)cancel_shown
{
  [self setCancelShown:cancel_shown withAnimation:YES];
}

- (void)setCancelShown:(BOOL)shown
         withAnimation:(BOOL)animate
{
  if (shown == _cancel_shown)
    return;
  _cancel_shown = shown;
  self.cancel_button.enabled = _cancel_shown;
  if (_cancel_shown)
    self.cancel_container.hidden = NO;

  CGFloat dx;
  CGAffineTransform transform;

  if (_cancel_shown)
  {
    dx = -(self.avatar_view.center.x + self.cancel_container.bounds.size.width) / 2.0f;
    transform = CGAffineTransformMakeRotation(M_PI);
  }
  else
  {
    dx = 0.0f;
    transform = CGAffineTransformIdentity;
  }
  if (animate)
  {
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       self.cancel_button.transform = transform;
       self.cancel_constraint.constant = dx;
       [self layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       if (!finished)
       {
         self.cancel_button.transform = transform;
         self.cancel_constraint.constant = dx;
       }
       if (!_cancel_shown)
         self.cancel_container.hidden = YES;
     }];
  }
  else
  {
    self.cancel_button.transform = transform;
    self.cancel_constraint.constant = dx;
    [self layoutIfNeeded];
  }
}

- (void)setAccept_shown:(BOOL)accept_shown
{
  [self setAcceptShown:accept_shown withAnimation:YES];
}

- (void)setAcceptShown:(BOOL)shown
         withAnimation:(BOOL)animate
{
  if (shown == _accept_shown)
    return;
  _accept_shown = shown;
  self.accept_button.enabled = _accept_shown;
  if (_accept_shown)
    self.accept_container.hidden = NO;

  CGFloat dx;
  CGAffineTransform transform;

  if (_accept_shown)
  {
    dx = -(self.avatar_view.center.x + self.accept_container.bounds.size.width) / 2.0f;
    transform = CGAffineTransformMakeRotation(2.0f * M_PI);
  }
  else
  {
    dx = 0.0f;
    transform = CGAffineTransformIdentity;
  }
  if (animate)
  {
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       self.accept_button.transform = transform;
       self.accept_constraint.constant = dx;
       [self layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       if (!finished)
       {
         self.accept_button.transform = transform;
         self.accept_constraint.constant = dx;
       }
       if (!_accept_shown)
         self.accept_container.hidden = YES;
     }];
  }
  else
  {
    self.accept_button.transform = transform;
    self.accept_constraint.constant = dx;
    [self layoutIfNeeded];
  }
}

- (IBAction)acceptTapped:(id)sender
{
  if (self.transaction.receivable)
  {
    [_delegate cellHadAcceptTappedForTransaction:self.transaction];
    [self setCancelShown:NO withAnimation:YES];
    [self setAcceptShown:NO withAnimation:YES];
  }
}

- (IBAction)cancelTapped:(id)sender
{
  self.cancel_shown = NO;
  [_delegate cellHadCancelTappedForTransaction:self.transaction];
  [self setCancelShown:NO withAnimation:YES];
  [self setAcceptShown:NO withAnimation:YES];
}

@end
