//
//  InfinitSendMediaViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendMediaViewController.h"

#import "InfinitSendGalleryCell.h"
#import "InfinitSelectPeopleViewController.h"
#import "InfinitTabBarController.h"

#import "ALAsset+Date.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import <Gap/InfinitTemporaryFileManager.h>

@interface InfinitSendMediaViewController ()

@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* next_button;

@end

@implementation InfinitSendMediaViewController
{
@private
  NSString* _cell_identifier;
  UITapGestureRecognizer* _nav_bar_tap;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _cell_identifier = @"gallery_cell";
    _assets = nil;
    _nav_bar_tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(navBarTapped)];
  }
  return self;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return UIStatusBarAnimationSlide;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.collectionView.allowsMultipleSelection = YES;

  self.navigationController.navigationBar.clipsToBounds = YES;
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  NSDictionary* clear_attrs = @{NSForegroundColorAttributeName: [UIColor clearColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  [self.next_button setTitleTextAttributes:nav_bar_attrs forState:UIControlStateNormal];
  [self.next_button setTitleTextAttributes:clear_attrs forState:UIControlStateDisabled];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.assets == nil)
    [self loadAssets];
  [self setNextButtonTitle];
  if (self.collectionView.indexPathsForSelectedItems.count == 0)
    self.next_button.enabled = NO;
  else
    self.next_button.enabled = YES;
  self.collectionView.contentOffset = CGPointMake(0.0f, 0.0f - self.collectionView.contentInset.top);
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.collectionViewLayout invalidateLayout];
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:_nav_bar_tap];
}

- (void)navBarTapped
{
  [self.collectionView scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController.navigationBar.subviews[0] removeGestureRecognizer:_nav_bar_tap];
  [super viewWillDisappear:animated];
}

- (void)loadAssets
{
  __block NSMutableArray* temp_assets = [NSMutableArray array];

  [[self defaultAssetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll
                                             usingBlock:^(ALAssetsGroup* group, BOOL* stop)
  {
    [group enumerateAssetsUsingBlock:^(ALAsset* result, NSUInteger index, BOOL* stop)
    {
      if (result)
      {
        [temp_assets addObject:result];
      }
    }];
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    self.assets = [temp_assets sortedArrayUsingDescriptors:@[sort]];
    [self.collectionView reloadData];
  } failureBlock:^(NSError* error)
  {
    NSLog(@"Error loading images %@", error);
  }];
}

#pragma mark - AssetsLibrary Call

- (ALAssetsLibrary*)defaultAssetsLibrary
{
  static dispatch_once_t pred = 0;
  static ALAssetsLibrary* library = nil;
  dispatch_once(&pred, ^{
    library = [[ALAssetsLibrary alloc] init];
  });
  return library;
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.assets.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitSendGalleryCell* cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:_cell_identifier
                                              forIndexPath:indexPath];

  ALAsset* asset = self.assets[self.assets.count - 1 - indexPath.row];

  if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
  {
    if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty)
    {
      NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"m:ss";
      NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
      cell.duration_label.text =
        [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:duration]];
      [cell.contentView addSubview:cell.duration_label];
    }
    cell.image_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                scale:1.0f
                                          orientation:UIImageOrientationUp];
  }
  else if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)
  {
    cell.image_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                scale:1.0f
                                          orientation:UIImageOrientationUp];
  }
  if ([self.collectionView.indexPathsForSelectedItems containsObject:indexPath])
    cell.selected = YES;
  else
    cell.selected = NO;
  return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  return CGSizeMake(self.view.frame.size.width / 3.0f - 4.0f,
                    self.view.frame.size.width / 3.0f - 4.0f);
}

# pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView
didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  [self collectionView:collectionView setSelected:YES atIndexPath:indexPath withAnimation:YES];
}

- (void)collectionView:(UICollectionView*)collectionView
didDeselectItemAtIndexPath:(NSIndexPath*)indexPath
{
  [self collectionView:collectionView setSelected:NO atIndexPath:indexPath withAnimation:YES];
}

- (void)collectionView:(UICollectionView*)collectionView
           setSelected:(BOOL)selected
           atIndexPath:(NSIndexPath*)indexPath
         withAnimation:(BOOL)animate
{
  InfinitSendGalleryCell* cell =
    (InfinitSendGalleryCell*)[collectionView cellForItemAtIndexPath:indexPath];
  if (animate)
  {
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       cell.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
       [cell.contentView layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       [UIView animateWithDuration:0.5f
                             delay:0.0f
            usingSpringWithDamping:0.3f
             initialSpringVelocity:10.0f
                           options:UIViewAnimationOptionCurveEaseInOut
                        animations:^
        {
          cell.transform = CGAffineTransformIdentity;
          [cell.contentView layoutIfNeeded];
        } completion:^(BOOL finished)
        {
          if (!finished)
          {
            cell.transform = CGAffineTransformIdentity;
          }
        }];
     }];
  }
  if (self.collectionView.indexPathsForSelectedItems.count == 0)
    self.next_button.enabled = NO;
  else
    self.next_button.enabled = YES;
  [self setNextButtonTitle];
}

- (IBAction)backButtonTapped:(id)sender
{
  for (NSIndexPath* path in self.collectionView.indexPathsForSelectedItems)
    [self.collectionView deselectItemAtIndexPath:path animated:NO];
  self.assets = nil;
  [(InfinitTabBarController*)self.tabBarController lastSelectedIndex];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  if([segue.identifier isEqualToString:@"send_to_segue"])
  {
    NSMutableArray* asset_urls = [NSMutableArray array];
    for (NSIndexPath* path in self.collectionView.indexPathsForSelectedItems)
    {
      [asset_urls addObject:self.assets[self.assets.count - 1 - path.row]];
    }
    InfinitSelectPeopleViewController* view_controller =
      (InfinitSelectPeopleViewController*)segue.destinationViewController;
    view_controller.asset_urls = asset_urls;
  }
}

- (void)setNextButtonTitle
{
  NSNumber* count = @(self.collectionView.indexPathsForSelectedItems.count);
  NSMutableString* next_str = [NSMutableString stringWithString:NSLocalizedString(@"Next", nil)];
  if (count.unsignedIntegerValue > 0)
    [next_str appendFormat:@" (%@)", count];
  [UIView performWithoutAnimation:^
  {
    self.next_button.title = next_str;
  }];
}

@end
