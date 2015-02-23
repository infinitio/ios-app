//
//  InfinitHomePeerTransactionCell.h
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitHomeAvatarView.h"
#import "InfinitHomeAbstractCell.h"

#import <Gap/InfinitPeerTransaction.h>

@protocol InfinitHomePeerTransactionCellProtocol;

@interface InfinitHomePeerTransactionCell : InfinitHomeAbstractCell

@property (nonatomic, weak) InfinitPeerTransaction* transaction;
@property (nonatomic, readwrite) BOOL expanded;

- (void)setUpWithDelegate:(id<InfinitHomePeerTransactionCellProtocol>)delegate
              transaction:(InfinitPeerTransaction*)transaction
                 expanded:(BOOL)expanded
                   avatar:(UIImage*)avatar;

- (void)setAvatar:(UIImage*)avatar;
- (void)updateProgressOverDuration:(NSTimeInterval)duration;

@end

@protocol InfinitHomePeerTransactionCellProtocol <NSObject>

- (void)cellAcceptTapped:(InfinitHomePeerTransactionCell*)sender;
- (void)cellRejectTapped:(InfinitHomePeerTransactionCell*)sender;

- (void)cellPauseTapped:(InfinitHomePeerTransactionCell*)sender;

- (void)cellCancelTapped:(InfinitHomePeerTransactionCell*)sender;

- (void)cellOpenTapped:(InfinitHomePeerTransactionCell*)sender;
- (void)cell:(InfinitHomePeerTransactionCell*)sender
openFileTapped:(NSUInteger)file_index;
- (void)cellSendTapped:(InfinitHomePeerTransactionCell*)sender;

@end
