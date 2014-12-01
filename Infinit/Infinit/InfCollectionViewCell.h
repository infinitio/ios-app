//
//  InfCollectionViewCell.h
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) UIImageView* checkMark;
@property (nonatomic, strong) UIDynamicAnimator* animator;
@property (nonatomic, strong) UILabel* durationLabel;

@end
