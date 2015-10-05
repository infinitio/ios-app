//
//  InfinitChecklistTableViewCell.m
//  Infinit
//
//  Created by Chris Crone on 29/09/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitChecklistTableViewCell.h"

#import "UIImage+GreyScale.h"

@interface InfinitChecklistTableViewCell ()

@property (nonatomic, strong) IBOutlet UILabel* action_label;
@property (nonatomic, strong) IBOutlet UILabel* description_label;
@property (nonatomic, strong) IBOutlet UIImageView* icon_view;

@end

@implementation InfinitChecklistTableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.enabled = YES;
}

- (void)setEnabled:(BOOL)enabled
{
  _enabled = enabled;
  CGFloat alpha = enabled ? 1.0f : 0.5f;
  self.action_label.alpha = alpha;
  self.description_label.alpha = alpha;
  NSString* image_name = nil;
  if ([self.reuseIdentifier rangeOfString:@"fb"].location != NSNotFound)
    image_name = @"icon-checklist-facebook";
  else if ([self.reuseIdentifier rangeOfString:@"twitter"].location != NSNotFound)
    image_name = @"icon-checklist-twitter";
  else if ([self.reuseIdentifier rangeOfString:@"avatar"].location != NSNotFound)
    image_name = @"icon-checklist-avatar";
  else if ([self.reuseIdentifier rangeOfString:@"invite"].location != NSNotFound)
    image_name = @"icon-checklist-invite";
  if (image_name.length)
    self.icon = [UIImage imageNamed:image_name];
}

- (void)setIcon:(UIImage*)icon
{
  UIImage* image = icon;
  if (!self.enabled)
    image = image.infinit_grey_scale_image;
  if (image)
    self.icon_view.image = image;
  self.icon_view.alpha = self.enabled ? 1.0f : 0.7f;
}

- (void)setTitle_str:(NSString*)title
{
  self.action_label.text = title;
}

- (void)setDescription_str:(NSString*)description
{
  self.description_label.text = description;
}

- (CGSize)icon_size
{
  return self.icon_view.bounds.size;
}

@end
