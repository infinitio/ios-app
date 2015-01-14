//
//  InfinitSendGalleryCell.h
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitSendGalleryCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView* image_view;
@property (nonatomic, strong) IBOutlet UIImageView* check_mark;
@property (nonatomic, strong) IBOutlet UIView* black_layer;
@property (nonatomic, strong) IBOutlet UILabel* duration_label;

@end
