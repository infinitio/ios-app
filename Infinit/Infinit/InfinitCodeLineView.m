//
//  InfinitCodeLineView.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitCodeLineView.h"

#import "InfinitColor.h"

@interface InfinitCodeLineView ()

@property (nonatomic, readonly) NSArray* lines;

@end

@implementation InfinitCodeLineView

- (void)awakeFromNib
{
  [super awakeFromNib];
  _lines = @[self.line_1, self.line_2, self.line_3, self.line_4, self.line_5];
}

- (void)setError:(BOOL)error
{
  _error = error;
  UIColor* color = error ? [InfinitColor colorWithRed:242 green:94 blue:90]
                         : [InfinitColor colorWithRed:91 green:99 blue:106];
  for (UIView* line in self.lines)
    line.backgroundColor = color;
}

@end
