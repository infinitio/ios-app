//
//  InfinitFilesCollectionCell_iPad.h
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFileModel.h"

@interface InfinitFilesCollectionCell_iPad : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIView* select_view;
@property (nonatomic, weak) IBOutlet UIImageView* thumbnail_view;
@property (nonatomic, weak) IBOutlet UIView* video_view;
@property (nonatomic, weak) IBOutlet UILabel* duration_label;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* h_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* w_constraint;

@property (nonatomic, copy) NSString* path;

- (void)configureForFile:(InfinitFileModel*)file 
           withThumbnail:(UIImage*)thumb;

@end
