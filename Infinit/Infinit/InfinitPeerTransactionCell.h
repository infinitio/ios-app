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

@property (weak) IBOutlet UILabel* filename;
@property (weak) IBOutlet UILabel* other_person;
@property (weak) IBOutlet UILabel* status;
@property (weak) IBOutlet UIButton* accept;
@property (weak) IBOutlet UIButton* reject;
@property (weak) InfinitPeerTransaction* transaction;

- (void)setUpCellWithTransaction:(InfinitPeerTransaction*)transaction;

@end
