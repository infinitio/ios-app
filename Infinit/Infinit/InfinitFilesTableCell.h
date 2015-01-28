//
//  InfinitFilesTableCell.h
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFileModel.h"
#import "InfinitFolderModel.h"

@interface InfinitFilesTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* duration_label;
@property (nonatomic, weak) IBOutlet UILabel* name_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UIImageView* icon_view;

- (void)configureCellWithFile:(InfinitFileModel*)file;
- (void)configureCellWithFolder:(InfinitFolderModel*)folder;

@end
