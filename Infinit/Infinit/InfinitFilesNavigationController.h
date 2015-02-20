//
//  InfinitFilesNavigationController.h
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitPortraitNavigationController.h"

#import "InfinitFolderModel.h"

@interface InfinitFilesNavigationController : InfinitPortraitNavigationController

@property (nonatomic, weak, readwrite) InfinitFolderModel* folder;
@property (nonatomic, readwrite) NSInteger file_index;

@end
