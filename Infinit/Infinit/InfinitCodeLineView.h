//
//  InfinitCodeLineView.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitCodeLineView : UIView

@property (nonatomic, weak) IBOutlet UIView* line_1;
@property (nonatomic, weak) IBOutlet UIView* line_2;
@property (nonatomic, weak) IBOutlet UIView* line_3;
@property (nonatomic, weak) IBOutlet UIView* line_4;
@property (nonatomic, weak) IBOutlet UIView* line_5;

@property (nonatomic, readwrite) BOOL error;

@end
