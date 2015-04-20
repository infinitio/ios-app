//
//  InfinitOverlayViewController.h
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitOverlayViewControllerProtocol;

@interface InfinitOverlayViewController : UIViewController

@property (nonatomic, readwrite) id<InfinitOverlayViewControllerProtocol> delegate;
@property (nonatomic, readonly) BOOL visible;

- (void)showController:(UIViewController*)controller;
- (void)hideController;

@end

@protocol InfinitOverlayViewControllerProtocol <NSObject>

- (void)overlayViewController:(InfinitOverlayViewController*)sender
      userDidCancelController:(UIViewController*)controller;

@end
