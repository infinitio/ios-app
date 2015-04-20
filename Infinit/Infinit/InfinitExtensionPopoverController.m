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
                                                 UICollectionViewDelegate,
                                                 UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UIView* container_view;
@property (nonatomic, weak) IBOutlet UILabel* files_label;
@property (nonatomic, weak) IBOutlet UICollectionView* files_view;
@property (nonatomic, weak) IBOutlet UIButton* send_button;

@property (nonatomic, readonly) NSArray* file_previews;

@end

static CGSize _cell_size = {0.0f, 0.0f};
static NSInteger _max_items = 9;

@implementation InfinitExtensionPopoverController
{
@private
  NSString* _file_cell_id;
  NSString* _more_cell_id;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      _cell_size = CGSizeMake(80.0f, 80.0f);
    else
      _cell_size = CGSizeMake(40.0f, 40.0f);
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _file_cell_id = @"extension_file_cell_id";
  _more_cell_id = @"extension_more_cell_id";

  UIColor* enabled_color = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  UIColor* disabled_color = [InfinitColor colorWithGray:128];
  [self.send_button setBackgroundImage:[self imageWithColor:enabled_color]
                              forState:UIControlStateNormal];
  [self.send_button setBackgroundImage:[self imageWithColor:disabled_color]
                              forState:UIControlStateDisabled];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
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
  [self.files_view reloadData];
}

- (void)beginAppearanceTransition:(BOOL)isAppearing
                         animated:(BOOL)animated
{
  [super beginAppearanceTransition:isAppearing animated:animated];
  [self endAppearanceTransition];
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

- (IBAction)sendTapped:(id)sender
{
  [self.delegate extensionPopoverWantsSend:self];
}

#pragma mark - UICollectionView

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  return _cell_size;
}

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
