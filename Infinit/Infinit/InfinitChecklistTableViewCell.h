//
//  InfinitChecklistTableViewCell.h
//  Infinit
//
//  Created by Chris Crone on 29/09/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitChecklistTableViewCell : UITableViewCell

@property (nonatomic, readwrite) NSString* description_str;
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readwrite) UIImage* icon;
@property (nonatomic, readonly) CGSize icon_size;
@property (nonatomic, readwrite) NSString* title_str;

@end
