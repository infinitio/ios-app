//
//  HomeLargeCollectionViewCell.h
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeLargeCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIButton* accept_button;
@property (weak, nonatomic) IBOutlet UIButton* cancel_button;
@property (weak, nonatomic) IBOutlet UIImageView* image_view;
@property (weak, nonatomic) IBOutlet UIImageView* blur_image_view;
@property (weak, nonatomic) IBOutlet UILabel* files_label;
@property (weak, nonatomic) IBOutlet UILabel* notification_label;

@end
