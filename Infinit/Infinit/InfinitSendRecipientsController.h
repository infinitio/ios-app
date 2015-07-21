//
//  InfinitSendRecipientsController.h
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContact.h"

@class InfinitManagedFiles;

@interface InfinitSendRecipientsController : UIViewController

@property (atomic, readwrite) NSUInteger file_count;
@property (atomic, weak, readwrite) InfinitManagedFiles* managed_files;
@property (nonatomic, weak, readwrite) InfinitContact* recipient;

- (void)resetView;

@end
