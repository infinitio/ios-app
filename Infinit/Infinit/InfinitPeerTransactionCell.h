//
//  InfinitPeerTransactionCell.h
//  Infinit
//
//  Created by Christopher Crone on 12/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitPeerTransaction.h>

@interface InfinitPeerTransactionCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* avatar;
@property (nonatomic, weak) IBOutlet UILabel* filename;
@property (nonatomic, weak) IBOutlet UILabel* other_person;
@property (nonatomic, weak) IBOutlet UILabel* status;

- (void)setupCellWithTransaction:(InfinitPeerTransaction*)transaction;

@end
