//
//  HomeSmallCollectionViewCell.h
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

@interface HomeSmallCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView* image_view;
@property (weak, nonatomic) IBOutlet UILabel* notification_label;

- (void)setUpWithTransaction:(InfinitPeerTransaction*)transaction;


@end
