//
//  FileListCell.h
//  Infinit
//
//  Created by Michael Dee on 12/22/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileListCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView* image_view;
@property (weak, nonatomic) IBOutlet UILabel* name_label;
@property (weak, nonatomic) IBOutlet UILabel* from_label;

@end
