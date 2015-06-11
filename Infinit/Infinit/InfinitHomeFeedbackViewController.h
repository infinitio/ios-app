//
//  InfinitHomeFeedbackViewController.h
//  Infinit
//
//  Created by Christopher Crone on 05/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitHomeFeedbackViewProtocol;

@interface InfinitHomeFeedbackViewController : UINavigationController

@property (nonatomic, assign) id<InfinitHomeFeedbackViewProtocol,
                                 UINavigationControllerDelegate> delegate;

@end

@protocol InfinitHomeFeedbackViewProtocol <NSObject>

- (void)feedbackViewControllerDidHide:(InfinitHomeFeedbackViewController*)sender;

@end
