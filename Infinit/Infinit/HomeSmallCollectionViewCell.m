//
//  HomeSmallCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "HomeSmallCollectionViewCell.h"

@implementation HomeSmallCollectionViewCell

- (void)awakeFromNib
{
  self.image_view.layer.cornerRadius = self.image_view.frame.size.height/2;
}

- (void)prepareForReuse
{
  self.notification_label.text = nil;
  self.image_view.image = nil;
}

- (void)setUpWithTransaction:(InfinitPeerTransaction*)transaction
{
  self.notification_label.text = [self statusText:transaction.status];
}

- (NSString*)statusText:(gap_TransactionStatus)status
{
  switch (status)
  {
    case gap_transaction_new:
      return @"new";
    case gap_transaction_on_other_device:
      return @"on_other_device";
    case gap_transaction_waiting_accept:
      return @"waiting_accept";
    case gap_transaction_waiting_data:
      return @"waiting_data";
    case gap_transaction_connecting:
      return @"connecting";
    case gap_transaction_transferring:
      return @"transferring";
    case gap_transaction_cloud_buffered:
      return @"cloud_buffered";
    case gap_transaction_finished:
      return @"finished";
    case gap_transaction_failed:
      return @"failed";
    case gap_transaction_canceled:
      return @"canceled";
    case gap_transaction_rejected:
      return @"rejected";
    case gap_transaction_deleted:
      return @"deleted";
    case gap_transaction_paused:
      return @"paused";
    default:
      return @"unknown";
  }
}


@end
