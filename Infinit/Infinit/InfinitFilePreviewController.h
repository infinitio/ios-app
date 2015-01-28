//
//  InfinitFilePreviewController.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFolderModel.h"

#import <QuickLook/QuickLook.h>

@interface InfinitFilePreviewController : QLPreviewController

+ (instancetype)controllerWithFolder:(InfinitFolderModel*)folder
                            andIndex:(NSInteger)index;

- (void)configureWithFolder:(InfinitFolderModel*)folder
                   andIndex:(NSInteger)index;

@end
