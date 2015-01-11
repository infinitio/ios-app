//
//  InfinitMediaCollectionViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitMediaCollectionViewController.h"

#import "InfinitGalleryViewCell.h"
#import "InfinitSelectPeopleViewController.h"
#import "InfinitTabBarController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import <Gap/InfinitTemporaryFileManager.h>

@interface InfinitMediaCollectionViewController ()

@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* next_button;

@end

@implementation InfinitMediaCollectionViewController
{
@private
  NSString* _cell_identifier;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _cell_identifier = @"gallery_cell";
  }
  return self;
}

- (void)viewDidLoad
{
  self.collectionView.allowsMultipleSelection = YES;
  [super viewDidLoad];
  [self.collectionView registerClass:[InfinitGalleryViewCell class]
          forCellWithReuseIdentifier:_cell_identifier];
  self.navigationController.navigationBar.clipsToBounds = YES;

  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  [self.next_button setTitleTextAttributes:nav_bar_attrs forState:UIControlStateNormal];
  [self loadAssets];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.assets == nil)
    [self loadAssets];
  [self setNextButtonTitle];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.collectionViewLayout invalidateLayout];
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
    self.assets = temp_assets;
    [self.collectionView reloadData];
  } failureBlock:^(NSError* error)
  {
    NSLog(@"Error loading images %@", error);
  }];
}

#pragma mark AssetsLibrary Call

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
  InfinitGalleryViewCell* cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:_cell_identifier
                                              forIndexPath:indexPath];

  ALAsset* asset = self.assets[self.assets.count - 1 - indexPath.row];
  cell.asset_url = asset.defaultRepresentation.url;

  if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
  {
    if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty)
    {
      NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"mm:ss";
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
  InfinitGalleryViewCell* cell =
    (InfinitGalleryViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
  if (animate)
  {
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       cell.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
     } completion:^(BOOL finished)
     {
       [UIView animateWithDuration:0.75f
                             delay:0.0f
            usingSpringWithDamping:0.3f
             initialSpringVelocity:25.0f
                           options:UIViewAnimationOptionCurveEaseInOut
                        animations:^
        {
          cell.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished)
        {
          if (!finished)
          {
            cell.transform = CGAffineTransformIdentity;
          }
        }];
     }];
  }
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
  if([segue.identifier isEqualToString:@"send2Segue"])
  {
    NSMutableArray* asset_urls = [NSMutableArray array];
    for (NSIndexPath* path in self.collectionView.indexPathsForSelectedItems)
    {
      InfinitGalleryViewCell* cell =
        (InfinitGalleryViewCell*)[self.collectionView cellForItemAtIndexPath:path];
      [asset_urls addObject:cell.asset_url];
    }
    InfinitSelectPeopleViewController* view_controller =
      (InfinitSelectPeopleViewController*)segue.destinationViewController;
    view_controller.asset_urls = asset_urls;
  }
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)setNextButtonTitle
{
  NSNumber* count = @(self.collectionView.indexPathsForSelectedItems.count);
  NSMutableString* next_str = [NSMutableString stringWithString:NSLocalizedString(@"Next", nil)];
  if (count.unsignedIntegerValue > 0)
    [next_str appendFormat:@" (%@)", count];
  [UIView performWithoutAnimation:^{
    self.next_button.title = next_str;
  }];
}

@end
