//
//  InfinitPeerTransactionCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitPeerTransactionCell.h"

@implementation InfinitPeerTransactionCell

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
    default:
      return @"unknown";
  }
}

- (void)setupCellWithTransaction:(InfinitPeerTransaction*)transaction
{
  if (transaction.sender.is_self)
    self.other_person.text = transaction.recipient.fullname;
  else
    self.other_person.text = transaction.sender.fullname;
  self.filename.text = transaction.files[0];
  self.status.text = [self statusText:transaction.status];
  self.accept.hidden = !transaction.receivable;
  self.accept.enabled = transaction.receivable;
  self.reject.hidden = !transaction.receivable;
  self.reject.enabled = transaction.receivable;
  [self setNeedsDisplay];
}

@end
