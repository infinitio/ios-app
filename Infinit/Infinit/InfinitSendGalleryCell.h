//
//  InfinitSendGalleryCell.h
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitSendGalleryCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView* thumbnail_view;
@property (nonatomic, weak) IBOutlet UIImageView* check_mark;
@property (nonatomic, weak) IBOutlet UIView* black_layer;

@property (nonatomic, weak) IBOutlet UIView* details_view;
@property (nonatomic, weak) IBOutlet UILabel* duration_label;

@property (nonatomic, readwrite) double video_duration;

@end
