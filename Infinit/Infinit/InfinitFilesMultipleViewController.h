//
//  InfinitFilesMultipleViewController.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFolderModel.h"

@interface InfinitFilesMultipleViewController : UIViewController

@property (nonatomic, weak, readwrite) InfinitFolderModel* folder;

@end
