//
//  InfinitLinkTransactionCell.h
//  Infinit
//
//  Created by Christopher Crone on 13/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitLinkTransaction.h>

@interface InfinitLinkTransactionCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* click_count;
@property (nonatomic, weak) IBOutlet UILabel* link;
@property (nonatomic, weak) IBOutlet UILabel* name;

- (void)setupCellWithTransaction:(InfinitLinkTransaction*)transaction;

@end
