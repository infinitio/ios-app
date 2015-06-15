//
//  InfinitInvitationOverlayViewController.h
//  Infinit
//
//  Created by Christopher Crone on 12/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContactAddressBook.h"
#import "InfinitMessagingRecipient.h"

@protocol InfinitInvitationOverlayProtocol;

@interface InfinitInvitationOverlayViewController : UIViewController

@property (nonatomic, copy) InfinitContactAddressBook* contact;
@property (nonatomic, weak) id<InfinitInvitationOverlayProtocol> delegate;

@end

@protocol InfinitInvitationOverlayProtocol <NSObject>

- (void)invitationOverlay:(InfinitInvitationOverlayViewController*)sender
             gotRecipient:(InfinitMessagingRecipient*)recipient;
- (void)invitationOverlayGotCancel:(InfinitInvitationOverlayViewController*)sender;

@end
