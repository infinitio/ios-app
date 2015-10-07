//
//  InfinitContactViewController.h
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContact.h"

@interface InfinitContactViewController : UIViewController

@property (nonatomic, weak, readwrite) InfinitContact* contact;
@property BOOL invitation_mode;

@end
