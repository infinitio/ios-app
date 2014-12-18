//
//  SendCell.m
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "SendCell.h"

@implementation SendCell

/*
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)reuseIdentifier
{
  
  
    self = [super initWithStyle:style
                reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        _portraitImageView = [[UIImageView alloc] initWithFrame:(CGRect){12,15,25,25}];
        
        _nameLabel = [[UILabel alloc] initWithFrame:(CGRect){90,10,200,21}];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.font = [UIFont boldSystemFontOfSize:12];
        
        _checkMark = [[UIImageView alloc] initWithFrame:(CGRect){250,10,23,23}];
        _checkMark.image = [UIImage imageNamed:@"icon-contact-check"];
        
        [self.contentView addSubview:_portraitImageView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_checkMark];
    }
    return self;
}
 */

- (void)awakeFromNib
{
  self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
  self.avatarImageView.clipsToBounds = YES;
}




- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
