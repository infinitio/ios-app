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

static NSDictionary* _norm_attrs = nil;
static NSDictionary* _bold_attrs = nil;

@implementation InfinitHomePeerTransactionCell

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.avatar_view.enable_progress = NO;
}

- (void)awakeFromNib
{
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
}

- (void)setUpWithTransaction:(InfinitPeerTransaction*)transaction
{
  _transaction = transaction;
  [self setBackgroundImage];
  [self updateAvatar];
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
  CGRect image_rect = self.background_view.bounds;
  UIGraphicsBeginImageContextWithOptions(image_rect.size, NO, 0.0f);
  UIBezierPath* rounded_corners = [UIBezierPath bezierPathWithRoundedRect:image_rect
                                                             cornerRadius:3.0f];
  [rounded_corners addClip];
  [[InfinitColor colorWithGray:41 alpha:0.8f] set];
  UIRectFill(image_rect);
  UIImage* background_image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.background_view.image = background_image;
}

- (void)setInfoString
{
  NSString* res = nil;
  NSRange bold_range = NSMakeRange(0, 0);
  NSString* file_count = [NSString stringWithFormat:NSLocalizedString(@"%@ files", nil),
                          @(self.transaction.files.count)];
  NSString* other_name = self.transaction.other_user.fullname;
  if (self.transaction.other_user.is_self)
    other_name = NSLocalizedString(@"me", nil);
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
      res = [NSString stringWithFormat:NSLocalizedString(@"Transfer of %@ with %@ on another device", nil),
             file_count, other_name];
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
      res = [NSString stringWithFormat:NSLocalizedString(@"Uploaded %@. Waiting for %@ to download", nil),
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
      res = [NSString stringWithFormat:NSLocalizedString(@"Transfer of %@ with %@ failed", nil),
             file_count, other_name];
      break;
    case gap_transaction_canceled:
      res = [NSString stringWithFormat:NSLocalizedString(@"Transfer of %@ with %@ canceled", nil),
             file_count, other_name];
      break;
    case gap_transaction_rejected:
      res = [NSString stringWithFormat:NSLocalizedString(@"Transfer of %@ with %@ rejected", nil),
             file_count, other_name];
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

@end
