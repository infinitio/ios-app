//
//  InfinitSettingsExpandedCell.h
//  Infinit
//
//  Created by Christopher Crone on 03/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitSettingsExpandedCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* title_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;

@end
