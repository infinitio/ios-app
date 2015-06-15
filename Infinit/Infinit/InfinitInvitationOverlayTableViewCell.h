//
//  InfinitInvitationOverlayTableViewCell.h
//  Infinit
//
//  Created by Christopher Crone on 12/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitInvitationOverlayTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton* button; // For lack of a better name.
@property (nonatomic, readonly) BOOL email;
@property (nonatomic, readonly) BOOL phone;

- (void)setupWithEmail:(NSString*)email;
- (void)setupWithPhoneNumber:(NSString*)phone;

@end
