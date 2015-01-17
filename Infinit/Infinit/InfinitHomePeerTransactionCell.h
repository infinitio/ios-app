//
//  InfinitHomePeerTransactionCell.h
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitHomeAvatarView.h"

#import <Gap/InfinitPeerTransaction.h>

@interface InfinitHomePeerTransactionCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView* background_view;
@property (nonatomic, weak) IBOutlet InfinitHomeAvatarView* avatar_view;
@property (nonatomic, weak) IBOutlet UILabel* time_label;
@property (nonatomic, weak) IBOutlet UILabel* size_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) InfinitPeerTransaction* transaction;

- (void)setUpWithTransaction:(InfinitPeerTransaction*)transaction;

- (void)updateAvatar;
- (void)updateProgressOverDuration:(NSTimeInterval)duration;
- (void)updateTimeString;

@end
