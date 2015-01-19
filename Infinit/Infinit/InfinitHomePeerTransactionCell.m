//
//  InfinitHomePeerTransactionCell.m
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomePeerTransactionCell.h"

#import "InfinitColor.h"

#import <Gap/InfinitTime.h>
#import <Gap/InfinitDataSize.h>

#import "UIImage+ImageEffects.h"

static NSDictionary* _norm_attrs = nil;
static NSDictionary* _bold_attrs = nil;
static UIImage* _mask_image = nil;

@interface InfinitHomePeerTransactionCell ()

@property (nonatomic, readonly) id<InfinitHomePeerTransactionCellProtocol> delegate;

@end

@implementation InfinitHomePeerTransactionCell

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.avatar_view.enable_progress = NO;
  [self setCancelShown:NO withAnimation:NO];
  _delegate = nil;
}

- (void)awakeFromNib
{
  if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
  {
    self.background_view.layer.cornerRadius = 3.0f;
    self.background_view.layer.masksToBounds = YES;
    UIBlurEffect* blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView* blur_view = [[UIVisualEffectView alloc] initWithEffect:blur];
    blur_view.frame = self.bounds;
    [self.background_view addSubview:blur_view];
  }
  self.layer.masksToBounds = NO;
  self.layer.shadowOpacity = 0.75f;
  self.layer.shadowColor = [InfinitColor colorWithGray:0 alpha:0.5f].CGColor;
  self.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
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
  UITapGestureRecognizer* tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(avatarTapped:)];
  [self.avatar_view addGestureRecognizer:tap];
  self.cancel_button.center = self.avatar_view.center;
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
  self.size_label.text = [InfinitDataSize fileSizeStringFrom:transaction.size];
}

- (void)setProgress
{
  if (self.transaction.status == gap_transaction_transferring)
  {
    self.avatar_view.progress = self.transaction.progress;
    self.avatar_view.enable_progress = YES;
  }
  else
  {
    self.avatar_view.enable_progress = NO;
  }
}

- (void)setBackgroundImage
{
  if (![[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
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
  if (self.transaction.other_user.is_self)
    other_name = NSLocalizedString(@"yourself", nil);
  switch (self.transaction.status)
  {
    case gap_transaction_new:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    {
      if (self.transaction.from_device)
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"Sending %@ to %@...", nil),
               file_count, other_name];
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
        res = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to accept %@", nil),
               other_name, file_count];
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"%@ wants to share %@", nil),
               other_name, file_count];
      }
      break;
    case gap_transaction_waiting_data:
      res = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to be online", nil),
             other_name];
      break;
    case gap_transaction_cloud_buffered:
      res = [NSString stringWithFormat:NSLocalizedString(@"Uploaded %@, waiting for %@ to download", nil),
             file_count, other_name];
      break;
    case gap_transaction_finished:
      if (self.transaction.from_device)
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
      if (self.transaction.other_user.is_self)
      {
        res = NSLocalizedString(@"You declined the transfer", nil);
      }
      else
      {
        res = [NSString stringWithFormat:NSLocalizedString(@"%@ declined the transfer", nil),
               other_name];
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
  if (self.transaction.done)
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

  CGAffineTransform transform;

  if (_cancel_shown)
  {
    CGFloat dx = (self.avatar_view.center.x + self.cancel_button.bounds.size.width) / 2.0f;

    CGAffineTransform translate = CGAffineTransformMakeTranslation(dx, 0.0f);
    CGAffineTransform roll = CGAffineTransformMakeRotation(M_PI);
    transform = CGAffineTransformConcat(translate, roll);
  }
  else
  {
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
       [self layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       if (!finished)
         self.cancel_button.transform = transform;
     }];
  }
  else
  {
    self.cancel_button.transform = transform;
  }
}

- (IBAction)cancelTapped:(id)sender
{
  self.cancel_shown = NO;
  [_delegate cellHadCancelTappedForTransaction:self.transaction];
}

@end
