//
//  ContactCell.h
//  Infinit
//
//  Created by Michael Dee on 12/21/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* name_label;
@property (weak, nonatomic) IBOutlet UIImageView* avatar_image_view;
@property (weak, nonatomic) IBOutlet UIButton* files_button;
@property (weak, nonatomic) IBOutlet UIButton* send_button;
@property (weak, nonatomic) IBOutlet UIButton* fav_button;

@end
