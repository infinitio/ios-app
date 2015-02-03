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

@property (nonatomic, strong) NSMutableArray* assets;
@property (nonatomic, weak, readwrite) InfinitContact* recipient;

- (void)resetView;

@end
