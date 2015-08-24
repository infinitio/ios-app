//
//  InfinitQuotaOverlayViewController.h
//  Infinit
//
//  Created by Christopher Crone on 19/08/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InfinitUser;

@protocol InfinitQuotaOverlayProtocol;

@interface InfinitQuotaOverlayViewController : UIViewController

@property (nonatomic, weak) id<InfinitQuotaOverlayProtocol> delegate;

- (void)configureForGhostDownloadLimit:(InfinitUser*)ghost;
- (void)configureForSendToSelfLimit;
- (void)configureForTransferSizeLimit;

@end

@protocol InfinitQuotaOverlayProtocol <NSObject>

- (void)quotaOverlayWantsClose:(InfinitQuotaOverlayViewController*)sender;

@end
