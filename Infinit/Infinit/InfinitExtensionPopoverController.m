//
//  InfinitExtensionPopoverController.m
//  Infinit
//
//  Created by Christopher Crone on 10/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitExtensionPopoverController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"
#import "InfinitExtensionFileCell.h"
#import "InfinitExtensionMoreCell.h"
#import "InfinitFilePreview.h"

@interface InfinitExtensionPopoverController () <UICollectionViewDataSource,
                                                 UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton* cancel_button;
@property (nonatomic, weak) IBOutlet UIView* container_view;
@property (nonatomic, weak) IBOutlet UIView* dark_view;
@property (nonatomic, weak) IBOutlet UILabel* files_label;
@property (nonatomic, weak) IBOutlet UICollectionView* files_view;
@property (nonatomic, weak) IBOutlet UIButton* send_button;

@property (nonatomic, readonly) NSArray* file_previews;

@end

static CGSize _cell_size = {40.0f, 40.0f};
static NSInteger _max_items = 9;

@implementation InfinitExtensionPopoverController
{
@private
  NSString* _file_cell_id;
  NSString* _more_cell_id;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _file_cell_id = @"extension_file_cell_id";
  _more_cell_id = @"extension_more_cell_id";
  [self addParallax];
  CGFloat corner_radius = 5.0f;
  self.container_view.layer.cornerRadius = corner_radius;
  self.container_view.layer.masksToBounds = NO;
  self.container_view.layer.shadowOpacity = 0.5f;
  self.container_view.layer.shadowRadius = 5.0f;
  self.container_view.layer.shadowColor = [UIColor blackColor].CGColor;
  self.container_view.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
  self.container_view.layer.shadowPath =
  [UIBezierPath bezierPathWithRoundedRect:self.container_view.bounds cornerRadius:5.0f].CGPath;

  self.cancel_button.showsTouchWhenHighlighted = YES;
  UIColor* enabled_color = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  UIColor* disabled_color = [InfinitColor colorWithGray:128];
  [self.send_button setBackgroundImage:[self imageWithColor:enabled_color]
                              forState:UIControlStateNormal];
  [self.send_button setBackgroundImage:[self imageWithColor:disabled_color]
                              forState:UIControlStateDisabled];

  UIBezierPath* bottom_mask = [UIBezierPath bezierPath];
  CGFloat w = self.container_view.bounds.size.width;
  CGFloat h = 50.0f;
  [bottom_mask moveToPoint:CGPointMake(0.0f, 0.0f)];
  [bottom_mask addLineToPoint:CGPointMake(w, 0.0f)];
  [bottom_mask addLineToPoint:CGPointMake(w, h - corner_radius)];
  [bottom_mask addArcWithCenter:CGPointMake(w - corner_radius, h - corner_radius)
                         radius:corner_radius
                     startAngle:0.0f
                       endAngle:M_PI_2
                      clockwise:YES];
  [bottom_mask addLineToPoint:CGPointMake(corner_radius, h)];
  [bottom_mask addArcWithCenter:CGPointMake(corner_radius, h - corner_radius)
                         radius:corner_radius
                     startAngle:M_PI_2
                       endAngle:M_PI
                      clockwise:YES];
  [bottom_mask closePath];
  CAShapeLayer* mask_layer = [CAShapeLayer layer];
  mask_layer.path = bottom_mask.CGPath;
  mask_layer.fillColor = [UIColor blackColor].CGColor;
  self.send_button.layer.mask = mask_layer;
  [self.view sendSubviewToBack:self.dark_view];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.dark_view.alpha = 0.0f;
  self.cancel_button.alpha = 0.0f;
  self.container_view.alpha = 0.0f;
  CGFloat screen_h = [UIScreen mainScreen].bounds.size.height;
  self.container_view.transform =
  CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
  NSString* files_text = nil;
  if (self.files.count == 1)
    files_text = NSLocalizedString(@"1 file", nil);
  else
    files_text = [NSString stringWithFormat:NSLocalizedString(@"%lu files", nil), self.files.count];
  NSString* str = [NSString stringWithFormat:NSLocalizedString(@"%@ selected", nil), files_text];
  NSMutableAttributedString* attr_str =
  [[NSMutableAttributedString alloc] initWithString:str attributes:[self textAttributesBold:NO]];
  NSRange bold_range = [str rangeOfString:files_text];
  if (bold_range.location != NSNotFound)
    [attr_str setAttributes:[self textAttributesBold:YES] range:bold_range];
  self.files_label.attributedText = attr_str;
}

- (void)beginAppearanceTransition:(BOOL)isAppearing
                         animated:(BOOL)animated
{
  [super beginAppearanceTransition:isAppearing animated:animated];
  [self endAppearanceTransition];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.files_view reloadData];
  [UIView animateWithDuration:0.4f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.dark_view.alpha = 1.0f;
   } completion:^(BOOL finished)
   {
     self.dark_view.alpha = 1.0f;
   }];
  [UIView animateWithDuration:0.3f
                        delay:0.2f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.cancel_button.alpha = 1.0f;
     self.container_view.alpha = 1.0f;
     self.container_view.transform = CGAffineTransformIdentity;
   } completion:^(BOOL finished)
   {
     self.cancel_button.alpha = 1.0f;
     self.container_view.alpha = 1.0f;
     self.container_view.transform = CGAffineTransformIdentity;
   }];
}

#pragma mark - Public

- (void)setFiles:(NSArray*)files
{
  _files = [files copy];
  NSMutableArray* previews = [NSMutableArray array];
  NSInteger count = 0;
  for (NSString* path in self.files)
  {
    UIImage* thumbnail = [InfinitFilePreview previewForPath:path ofSize:_cell_size crop:YES];
    if (thumbnail)
    {
      [previews addObject:thumbnail];
      if (count++ == _max_items)
        break;
    }
  }
  _file_previews = [previews copy];
}

#pragma mark - Button Handling

- (void)doneAnimationWithSend:(BOOL)send
{
  CGFloat screen_h = [UIScreen mainScreen].bounds.size.height;
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.cancel_button.alpha = 0.0f;
     self.container_view.alpha = 0.0f;
     self.container_view.transform =
       CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
   } completion:^(BOOL finished)
   {
     self.cancel_button.alpha = 0.0f;
     self.container_view.alpha = 0.0f;
     self.container_view.transform =
       CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
   }];
  [UIView animateWithDuration:0.4f
                        delay:0.2f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.dark_view.alpha = 0.0f;
   } completion:^(BOOL finished)
   {
     self.dark_view.alpha = 0.0f;
     if (send)
     {
       [self.delegate extensionPopoverWantsSend:self];
     }
     else
     {
       [self.delegate extensionPopoverWantsCancel:self];
     }
   }];
}

- (IBAction)cancelTapped:(id)sender
{
  [self doneAnimationWithSend:NO];
}

- (IBAction)sendTapped:(id)sender
{
  [self doneAnimationWithSend:YES];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.file_previews.count > _max_items ? _max_items + 1 : self.file_previews.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  UICollectionViewCell* res = nil;
  if (indexPath.row < _max_items || self.files.count == _max_items + 1)
  {
    InfinitExtensionFileCell* cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:_file_cell_id forIndexPath:indexPath];
    cell.thumbnail = self.file_previews[indexPath.row];
    res = cell;
  }
  else
  {
    InfinitExtensionMoreCell* cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:_more_cell_id forIndexPath:indexPath];
    cell.count = self.files.count - _max_items;
    res = cell;
  }
  return res;
}

#pragma mark - Helpers

- (void)addParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* vertical =
  [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  vertical.minimumRelativeValue = @(-10.0f);
  vertical.maximumRelativeValue = @(10.0f);

  // Set horizontal effect
  UIInterpolatingMotionEffect* horizontal =
  [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                  type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontal.minimumRelativeValue = @(-10.0f);
  horizontal.maximumRelativeValue = @(10.0f);

  // Create group to combine both
  UIMotionEffectGroup* group = [UIMotionEffectGroup new];
  group.motionEffects = @[horizontal, vertical];

  // Add both effects to your view
  [self.container_view addMotionEffect:group];
}

- (UIImage*)imageWithColor:(UIColor*)color
{
  UIImage* res = nil;
  CGRect cancel_rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
  UIGraphicsBeginImageContext(cancel_rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, cancel_rect);
  res = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return res;
}

- (NSDictionary*)textAttributesBold:(BOOL)bold
{
  UIFont* font = nil;
  if (bold)
    font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
  else
    font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
  return @{NSFontAttributeName: font,
           NSParagraphStyleAttributeName: [NSParagraphStyle defaultParagraphStyle],
           NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73]};
}

@end
