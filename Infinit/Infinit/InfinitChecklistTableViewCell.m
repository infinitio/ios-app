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

static UIImage* _done_image = nil;

@implementation InfinitChecklistTableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  if (!_done_image)
    _done_image = [UIImage imageNamed:@"icon-checklist-done"];
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
  else if ([self.reuseIdentifier rangeOfString:@"device"].location != NSNotFound)
    image_name = @"icon-checklist-device";
  else if ([self.reuseIdentifier rangeOfString:@"invite"].location != NSNotFound)
    image_name = @"icon-checklist-invite";
  if (image_name.length && enabled)
    self.icon_view.image = [UIImage imageNamed:image_name];
  else if (image_name)
    self.icon_view.image = _done_image;
}

- (void)setAvatar:(UIImage*)avatar
{
  __weak InfinitChecklistTableViewCell* weak_self = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    UIImage* grey_image = avatar.infinit_grey_scale_image;
    dispatch_async(dispatch_get_main_queue(), ^
    {
      weak_self.icon_view.image = grey_image;
    });
  });
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
