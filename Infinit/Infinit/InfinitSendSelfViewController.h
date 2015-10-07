//
//  InfinitSendSelfViewController.h
//  Infinit
//
//  Created by Chris Crone on 06/10/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InfinitManagedFiles;

@interface InfinitSendSelfViewController : UIViewController

@property (atomic, weak, readwrite) InfinitManagedFiles* managed_files;

@end
