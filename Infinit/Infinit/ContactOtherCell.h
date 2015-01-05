//
//  ContactOtherCell.h
//  Infinit
//
//  Created by Michael Dee on 12/26/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactOtherCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView* avatar_image_view;
@property (weak, nonatomic) IBOutlet UILabel* name_label;
@property (weak, nonatomic) IBOutlet UILabel* info_label;
@property (weak, nonatomic) IBOutlet UIButton* invite_button;

@end
