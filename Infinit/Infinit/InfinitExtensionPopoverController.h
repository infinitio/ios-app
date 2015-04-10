//
//  InfinitExtensionPopoverController.h
//  Infinit
//
//  Created by Christopher Crone on 10/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitExtensionPopoverProtocol;

@interface InfinitExtensionPopoverController : UIViewController

@property (nonatomic, readwrite) id<InfinitExtensionPopoverProtocol> delegate;
@property (nonatomic, readwrite, copy) NSArray* files;

@end

@protocol InfinitExtensionPopoverProtocol <NSObject>

- (void)extensionPopoverWantsCancel:(InfinitExtensionPopoverController*)sender;
- (void)extensionPopoverWantsSend:(InfinitExtensionPopoverController*)sender;

@end
