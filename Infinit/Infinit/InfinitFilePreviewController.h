//
//  InfinitFilePreviewController.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

#import "InfinitFileModel.h"

@interface InfinitFilePreviewController : QLPreviewController

@property (nonatomic, weak, readwrite) InfinitFileModel* file;

+ (instancetype)controllerWithFile:(InfinitFileModel*)file;

@end
