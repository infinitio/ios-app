//
//  InfinitPeerSendController.h
//  Infinit
//
//  Created by Christopher Crone on 13/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitPeerSendController : UIViewController <UIImagePickerControllerDelegate,
                                                         UINavigationControllerDelegate,
                                                         UITableViewDataSource,
                                                         UITableViewDelegate>

@property (nonatomic) UIImagePickerController* image_picker_controller;
@property (nonatomic, weak) IBOutlet UITextField* recipient;
@property (nonatomic, weak) IBOutlet UIButton* send;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end
