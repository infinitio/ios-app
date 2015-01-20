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

@property (nonatomic, weak) IBOutlet InfinitHomeAvatarView* avatar_view;
@property (nonatomic, weak) IBOutlet UIImageView* background_view;
@property (nonatomic, weak) IBOutlet UIButton* cancel_button;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UILabel* size_label;
@property (nonatomic, weak) IBOutlet UILabel* time_label;
@property (nonatomic, weak) IBOutlet UIImageView* status_view;

@property (nonatomic, weak) InfinitPeerTransaction* transaction;
@property (nonatomic, readwrite) BOOL cancel_shown;

- (void)setUpWithDelegate:(id<InfinitHomePeerTransactionCellProtocol>)delegate
              transaction:(InfinitPeerTransaction*)transaction;

- (void)updateAvatar;
- (void)updateProgressOverDuration:(NSTimeInterval)duration;
- (void)updateTimeString;

@end

@protocol InfinitHomePeerTransactionCellProtocol <NSObject>

- (void)cellHadCancelTappedForTransaction:(InfinitTransaction*)transaction;

@end
