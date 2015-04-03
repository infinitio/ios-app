//
//  InfinitFilesBottomBar.h
//  Infinit
//
//  Created by Christopher Crone on 25/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitFilesBottomBar : UIView

@property (nonatomic, weak) IBOutlet UIButton* delete_button;
@property (nonatomic, weak) IBOutlet UIButton* save_button;
@property (nonatomic, weak) IBOutlet UIButton* send_button;

@property (nonatomic, readwrite) BOOL enabled;

@end
