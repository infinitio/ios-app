//
//  InfinitGalleryViewCell.h
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitGalleryViewCell : UICollectionViewCell

@property (nonatomic, strong) NSURL* asset_url;
@property (nonatomic, strong) UIImageView* image_view;
@property (nonatomic, strong) UIImageView* check_mark;
@property (nonatomic, strong) UIView* black_layer;
@property (nonatomic, strong) UILabel* duration_label;

@end
