// VENToken.m
//
// Copyright (c) 2014 Venmo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VENToken.h"

#import "InfinitColor.h"

@interface VENToken ()
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation VENToken

- (id)initWithFrame:(CGRect)frame
{
    self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    if (self) {
        [self setUpInit];
    }
    return self;
}

- (void)setUpInit
{
    self.layer.cornerRadius = self.frame.size.height / 2.0f;
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapToken:)];
    self.colorScheme = [UIColor blueColor];
    self.textColor = [UIColor whiteColor];
    self.titleLabel.textColor = self.textColor;
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setTitleText:(NSString *)text
{
    self.titleLabel.text = text;
    self.titleLabel.textColor = self.textColor;
    [self.titleLabel sizeToFit];
    self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame), CGRectGetMaxX(self.titleLabel.frame) + 15.0f, CGRectGetHeight(self.frame));
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectMake((self.frame.size.width - self.titleLabel.frame.size.width) / 2.0f,
                                       (self.frame.size.height - self.titleLabel.frame.size.height) / 2.0f,
                                       self.titleLabel.frame.size.width,
                                       self.titleLabel.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
  UIColor *backgroundColor = highlighted ? [InfinitColor colorWithRed:35 green:168 blue:167] : [InfinitColor colorFromPalette:ColorShamRock];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.backgroundColor = backgroundColor;
}

- (void)setColorScheme:(UIColor *)colorScheme
{
    _colorScheme = colorScheme;
    self.backgroundColor = colorScheme;
    [self setHighlighted:_highlighted];
}

- (void)setTitleTextColor:(UIColor *)color
{
  _textColor = color;
  self.titleLabel.textColor = color;
}


#pragma mark - Private

- (void)didTapToken:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.didTapTokenBlock) {
        self.didTapTokenBlock();
    }
}

@end
