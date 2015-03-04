//
//  InfinitHomePeerTransactionFileCell.h
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitPeerTransaction.h>

@interface InfinitHomePeerTransactionFileCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView* file_icon_view;
@property (nonatomic, weak) IBOutlet UILabel* file_name_label;

@property (nonatomic, readwrite) NSString* filename;
@property (nonatomic, readwrite) UIImage* thumbnail;

@end
