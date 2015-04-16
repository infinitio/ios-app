//
//  InfinitFilesTableCell_iPad.h
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFileModel.h"
#import "InfinitFolderModel.h"

@interface InfinitFilesTableCell_iPad : UITableViewCell

+ (NSString*)cell_id;
+ (CGFloat)height;

@property (nonatomic, weak) IBOutlet UIImageView* thumbnail_view;
@property (nonatomic, weak) IBOutlet UILabel* filename_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;

- (void)configureForFile:(InfinitFileModel*)file;
- (void)configureForFolder:(InfinitFolderModel*)folder;

@end
