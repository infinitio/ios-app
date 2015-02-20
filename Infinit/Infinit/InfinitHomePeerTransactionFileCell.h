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

- (void)setFilename:(NSString*)filename;
- (void)setThumbnail:(UIImage*)thumbnail;

@end
