//
//  InfinitCheckView.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitCheckView : UIView

@property (nonatomic, readwrite) BOOL checked;

- (void)setChecked:(BOOL)checked
          animated:(BOOL)animate;

@end
