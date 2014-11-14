//
//  InfinitLinkSendController.h
//  Infinit
//
//  Created by Christopher Crone on 14/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitLinkSendController : UIViewController <UIImagePickerControllerDelegate,
                                                         UINavigationControllerDelegate,
                                                         UITableViewDataSource,
                                                         UITableViewDelegate>

@property (nonatomic) UIImagePickerController* image_picker_controller;
@property (nonatomic, weak) IBOutlet UIButton* send;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end
