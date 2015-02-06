//
//  InfinitSettingsUserCell.h
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitUser.h>

@interface InfinitSettingsUserCell : UITableViewCell

- (void)configureWithUser:(InfinitUser*)user;

@end
