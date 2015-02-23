//
//  InfinitSendNoResultsCell.h
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitSendNoResultsCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* message_label;
@property (nonatomic, weak) IBOutlet UIButton* facebook_button;
@property (nonatomic, weak) IBOutlet UIButton* contacts_button;

@property (nonatomic, readwrite) BOOL show_buttons;

@end
