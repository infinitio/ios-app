//
//  InfinitSendRecipientsController.h
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContact.h"

@interface InfinitSendRecipientsController : UIViewController

/// List of ALAssets or PHAssets.
@property (nonatomic, strong) NSArray* assets;
/// List of file paths as NSStrings.
@property (nonatomic, copy) NSArray* files;
/// String UUID of managed files.
@property (nonatomic, copy) NSString* extension_files_uuid;
@property (nonatomic, weak, readwrite) InfinitContact* recipient;

- (void)resetView;

@end
