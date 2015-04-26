//
//  InfinitWelcomeAbstractViewController.h
//  Infinit
//
//  Created by Christopher Crone on 24/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitStateResult.h>

typedef void(^InfinitWelcomeResultBlock)(InfinitStateResult* result);

@protocol InfinitWelcomeAbstractProtocol;

@interface InfinitWelcomeAbstractViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel* info_label;

@property (nonatomic, readonly) UIColor* normal_color;
@property (nonatomic, readonly) UIColor* error_color;

@property (nonatomic, readonly) NSParagraphStyle* spaced_style;

- (void)shakeField:(UITextField*)field
           andLine:(UIView*)line;

- (void)resetView;

@end

@protocol InfinitWelcomeAbstractProtocol <NSObject>

- (NSString*)errorStringForGapStatus:(gap_Status)status;

@end
