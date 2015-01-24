//
//  InfinitFilesTableCell.h
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitFilesTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* name_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UIImageView* icon_view;

- (void)configureCellForPath:(NSString*)path;

@end
