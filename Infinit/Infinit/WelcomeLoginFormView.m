//
//  WelcomeLoginFormView.m
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "WelcomeLoginFormView.h"

@implementation WelcomeLoginFormView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)awakeFromNib
{
  self.avatar_button.layer.cornerRadius = self.avatar_button.frame.size.height/2;
  self.avatar_button.layer.borderWidth = 1.0;
  self.avatar_button.layer.borderColor = [[UIColor colorWithRed:194/255.0 green:211/255.0 blue:211/255.0 alpha:1] CGColor];
  self.avatar_button.clipsToBounds = YES;

  
  CGFloat spacing = 6.0;
  CGSize titleSize = [self.avatar_button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.avatar_button.titleLabel.font}];
  self.avatar_button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing),
                                                        0.0,
                                                        0.0,
                                                        -titleSize.width);
  
  CGSize imageSize = self.avatar_button.imageView.image.size;
  self.avatar_button.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                        -imageSize.width,
                                                        -(imageSize.height + spacing),
                                                        0.0);
  
}



@end
