//
//  InfinitSendGalleryController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendGalleryController.h"

#import "InfinitHostDevice.h"
#import "InfinitMetricsManager.h"
#import "InfinitSendGalleryCell.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitSendSelfViewController.h"
#import "InfinitTabBarController.h"

#import "ALAsset+Date.h"
#import "UICollectionView+Convenience.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitTemporaryFileManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.SendGalleryViewController");

@interface InfinitSendGalleryController () <UICollectionViewDataSource,
                                            UICollectionViewDelegate,
                                            UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UICollectionView* collection_view;
@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* next_constraint;
@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout* layout;

@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, strong) PHCachingImageManager* image_caching_manager;
@property (nonatomic, readwrite, copy) NSArray* last_selection;
@property (atomic, readwrite, weak) InfinitManagedFiles* managed_files;
@property (nonatomic, strong) UITapGestureRecognizer* nav_bar_tap;
@property (nonatomic, readwrite) CGRect previous_preheat_rect;
@property (nonatomic, readonly) BOOL selected_something;

@end

static CGSize _asset_size = {0.0f, 0.0f};
static CGSize _cell_size = {0.0f, 0.0f};
static NSString* _cell_identifier = @"gallery_cell";

@implementation InfinitSendGalleryController

- (void)resetCellSize
{
  CGFloat width = self.view.bounds.size.width;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    width -= 10.0f;
  CGFloat diameter = diameter = floor(width / 3.0f) - 5.0f;
  _cell_size = CGSizeMake(diameter, diameter);
  CGFloat scale = [UIScreen mainScreen].scale;
  _asset_size = CGSizeMake(diameter * scale, diameter * scale);
  [self.collection_view.collectionViewLayout invalidateLayout];
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _assets = nil;
    _nav_bar_tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(navBarTapped)];
    self.dark = YES;
  }
  return self;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [UIView animateWithDuration:(duration > 0.2f ? 0.2f : duration)
                   animations:^
  {
    self.collection_view.alpha = 0.0f;
  }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [self resetCellSize];
  [self resetCachedAssets];
  [UIView animateWithDuration:0.2f
                   animations:^
  {
    self.collection_view.alpha = 1.0f;
  }];
}

- (void)viewDidLoad
{
  _image_caching_manager = [[PHCachingImageManager alloc] init];
  self.collection_view.alwaysBounceVertical = YES;
  [super viewDidLoad];
  self.collection_view.allowsMultipleSelection = YES;

  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSendGalleryCell.class)
                                   bundle:nil];
  [self.collection_view registerNib:cell_nib forCellWithReuseIdentifier:_cell_identifier];

  [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init]
                                                forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    self.next_button.hidden = YES;
    self.navigationItem.title = NSLocalizedString(@"SELECT FILES", nil);
    self.navigationItem.leftBarButtonItem = nil;
  }
  else
  {
    self.next_button.titleEdgeInsets =
      UIEdgeInsetsMake(0.0f,
                       - self.next_button.imageView.frame.size.width,
                       0.0f,
                       self.next_button.imageView.frame.size.width);
    self.next_button.imageEdgeInsets =
      UIEdgeInsetsMake(0.0f,
                       self.next_button.titleLabel.frame.size.width + 10.0f,
                       0.0f,
                       - (self.next_button.titleLabel.frame.size.width + 10.0f));
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self configureNextButton];
  self.collection_view.contentOffset =
    CGPointMake(0.0f, 0.0f - self.collection_view.contentInset.top);
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (self.collection_view.indexPathsForSelectedItems.count == 0)
  {
    [self resetCellSize];
    [self loadAssets];
    _selected_something = NO;
  }
  [self updateCachedAssets];
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:self.nav_bar_tap];
}

- (void)navBarTapped
{
  [self.collection_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController.navigationBar.subviews[0] removeGestureRecognizer:self.nav_bar_tap];
  [self resetCachedAssets];
  [super viewWillDisappear:animated];
}

- (void)loadAssets
{
  if ([InfinitHostDevice PHAssetClass])
  {
    PHFetchOptions* options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                              ascending:NO]];
    PHFetchResult* assets = [PHAsset fetchAssetsWithOptions:options];
    __block NSMutableArray* temp_assets = [NSMutableArray array];
    __block NSMutableArray* except_list = [NSMutableArray array];
    [assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
      [temp_assets addObject:obj];
    }];
    PHFetchResult* collections =
      [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                               subtype:PHAssetCollectionSubtypeAlbumCloudShared
                                               options:nil];
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection* collection,
                                              NSUInteger idx,
                                              BOOL* stop)
    {
      PHFetchResult* assets2 = [PHAsset fetchAssetsInAssetCollection:collection options:options];
      [assets2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
      {
        [except_list addObject:obj];
      }];
    }];
    [temp_assets removeObjectsInArray:except_list];
    self.assets = [temp_assets copy];
    [self.collection_view reloadData];
  }
  else
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
      NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
      self.assets = [temp_assets sortedArrayUsingDescriptors:@[sort]];
      [self.collection_view reloadData];
    } failureBlock:^(NSError* error)
    {
      NSLog(@"Error loading images %@", error);
    }];
  }
}

#pragma mark - Asset Caching

- (void)resetCachedAssets
{
  [self.image_caching_manager stopCachingImagesForAllAssets];
  self.previous_preheat_rect = CGRectZero;
}

- (void)updateCachedAssets
{
  if (![InfinitHostDevice PHAssetClass])
    return;
  BOOL visible = self.isViewLoaded && self.view.window != nil;
  if (!visible)
    return;

  // The preheat window is twice the height of the visible rect
  CGRect preheat_rect = self.collection_view.bounds;
  preheat_rect = CGRectInset(preheat_rect, 0.0f, - 0.5f * CGRectGetHeight(preheat_rect));

  // If scrolled by a "reasonable" amount...
  CGFloat delta = ABS(CGRectGetMidY(preheat_rect) - CGRectGetMidY(self.previous_preheat_rect));
  if (delta > CGRectGetHeight(self.collection_view.bounds) / 3.0f)
  {
    // Compute the assets to start caching and to stop caching.
    NSMutableArray* added_indexes = [NSMutableArray array];
    NSMutableArray* removed_indexes = [NSMutableArray array];

    [self computeDifferenceBetweenRect:self.previous_preheat_rect
                               andRect:preheat_rect
                        removedHandler:^(CGRect removed_rect)
    {
      NSArray* indexes = [self.collection_view infinit_indexPathsForElementsInRect:removed_rect];
      [removed_indexes addObjectsFromArray:indexes];
    } addedHandler:^(CGRect added_rect)
    {
      NSArray* indexes = [self.collection_view infinit_indexPathsForElementsInRect:added_rect];
      [added_indexes addObjectsFromArray:indexes];
    }];

    NSArray* assets_to_start_caching = [self assetsAtIndexPaths:added_indexes];
    NSArray* assets_to_stop_caching = [self assetsAtIndexPaths:removed_indexes];

    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;

    [self.image_caching_manager startCachingImagesForAssets:assets_to_start_caching
                                        targetSize:_asset_size
                                       contentMode:PHImageContentModeAspectFill
                                           options:nil];
    [self.image_caching_manager stopCachingImagesForAssets:assets_to_stop_caching
                                       targetSize:_asset_size
                                      contentMode:PHImageContentModeAspectFill
                                          options:nil];

    self.previous_preheat_rect = preheat_rect;
  }
}

- (void)computeDifferenceBetweenRect:(CGRect)old_rect
                             andRect:(CGRect)new_rect
                      removedHandler:(void (^)(CGRect removed_rect))removedHandler
                        addedHandler:(void (^)(CGRect added_rect))addedHandler
{
  if (CGRectIntersectsRect(new_rect, old_rect))
  {
    CGFloat old_max_y = CGRectGetMaxY(old_rect);
    CGFloat old_min_y = CGRectGetMinY(old_rect);
    CGFloat new_max_y = CGRectGetMaxY(new_rect);
    CGFloat new_min_y = CGRectGetMinY(new_rect);
    if (new_max_y > old_max_y)
    {
      CGRect rect_to_add = CGRectMake(new_rect.origin.x, old_max_y,
                                      new_rect.size.width, (new_max_y - old_max_y));
      addedHandler(rect_to_add);
    }
    if (old_min_y > new_min_y)
    {
      CGRect rect_to_add = CGRectMake(new_rect.origin.x, new_min_y,
                                      new_rect.size.width, (old_min_y - new_min_y));
      addedHandler(rect_to_add);
    }
    if (new_max_y < old_max_y)
    {
      CGRect rect_to_remove = CGRectMake(new_rect.origin.x, new_max_y,
                                         new_rect.size.width, (old_max_y - new_max_y));
      removedHandler(rect_to_remove);
    }
    if (old_min_y < new_min_y)
    {
      CGRect rect_to_remove = CGRectMake(new_rect.origin.x, old_min_y,
                                         new_rect.size.width, (new_min_y - old_min_y));
      removedHandler(rect_to_remove);
    }
  }
  else
  {
    addedHandler(new_rect);
    removedHandler(old_rect);
  }
}

- (NSArray*)assetsAtIndexPaths:(NSArray*)indexPaths
{
  if (indexPaths.count == 0)
    return nil;

  NSMutableArray* assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
  for (NSIndexPath* indexPath in indexPaths)
  {
    PHAsset* asset = self.assets[indexPath.item];
    [assets addObject:asset];
  }
  return assets;
}

#pragma mark - General

- (void)resetView
{
  self.assets = nil;
  self.managed_files = nil;
  for (NSIndexPath* path in self.collection_view.indexPathsForSelectedItems)
    [self.collection_view deselectItemAtIndexPath:path animated:NO];
}

#pragma mark - AssetsLibrary Call

- (ALAssetsLibrary*)defaultAssetsLibrary
{
  static dispatch_once_t pred = 0;
  static ALAssetsLibrary* library = nil;
  dispatch_once(&pred, ^
  {
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

  if ([InfinitHostDevice PHAssetClass])
  {
    NSInteger current_tag = cell.tag + 1;
    cell.tag = current_tag;
    PHAsset* asset = self.assets[indexPath.row];
    [self.image_caching_manager requestImageForAsset:asset
                                          targetSize:_asset_size
                                         contentMode:PHImageContentModeAspectFill
                                             options:nil
                                       resultHandler:^(UIImage* result, NSDictionary* info)
     {
       if (cell.tag == current_tag)
       {
         cell.thumbnail_view.image = result;
       }
       else
       {
         InfinitSendGalleryCell* old_cell =
          (InfinitSendGalleryCell*)[collectionView cellForItemAtIndexPath:indexPath];
         old_cell.thumbnail_view.image = result;
       }
     }];
    if (asset.mediaType == PHAssetMediaTypeVideo)
    {
      cell.video_duration = asset.duration;
    }
  }
  else
  {
    ALAsset* asset = self.assets[indexPath.row];

    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
    {
      if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty)
      {
        NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
        cell.video_duration = duration;
      }
      cell.thumbnail_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                  scale:1.0f
                                            orientation:UIImageOrientationUp];
    }
    else if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)
    {
      cell.thumbnail_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                      scale:1.0f
                                                orientation:UIImageOrientationUp];
    }
  }
  if ([self.collection_view.indexPathsForSelectedItems containsObject:indexPath])
    cell.selected = YES;
  else
    cell.selected = NO;
  return cell;
}

#pragma mark - Scroll Delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
  [self updateCachedAssets];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  return _cell_size;
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return UIEdgeInsetsMake(0.0f, 5.0f, 0.0f, 5.0f);
  else
    return UIEdgeInsetsZero;
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
    [UIView animateWithDuration:animate ? 0.1f : 0.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       cell.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
       [cell.contentView layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       [UIView animateWithDuration:animate ? 0.15f : 0.0f
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
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    NSMutableArray* assets = [NSMutableArray array];
    for (NSIndexPath* path in self.collection_view.indexPathsForSelectedItems)
    {
      id asset = self.assets[path.row];
      [assets addObject:asset];
    }
    [self.delegate sendGalleryView:self selectedAssets:assets];
  }
  else
  {
    [self configureNextButton];
  }
  if (!_selected_something)
  {
    _selected_something = YES;
    [InfinitMetricsManager sendMetric:InfinitUIEventSendGallerySelectedElement
                               method:InfinitUIMethodTap];
  }
}

- (IBAction)backButtonTapped:(id)sender
{
  // WORKAROUND: For some reason the view is resized when transitioning back which makes the next
  // button show.
  self.next_constraint.constant = - 3.0f * self.next_button.bounds.size.height;
  [(InfinitTabBarController*)self.tabBarController lastSelectedIndex];
  [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:self.managed_files];
  self.managed_files = nil;
}

- (IBAction)nextButtonTapped:(id)sender
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    NSString* segue_id = @"send_to_segue";
    if ([InfinitHostDevice english] && ![InfinitDeviceManager sharedInstance].other_devices.count)
      segue_id = @"gallery_self_only";
    [self performSegueWithIdentifier:segue_id sender:sender];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  NSMutableArray* assets = [NSMutableArray array];
  for (NSIndexPath* path in self.collection_view.indexPathsForSelectedItems)
  {
    id asset = self.assets[path.row];
    [assets addObject:asset];
  }
  InfinitTemporaryFileManager* manager = [InfinitTemporaryFileManager sharedInstance];
  if (!self.managed_files)
    self.managed_files = [manager createManagedFiles];
  __weak InfinitSendGalleryController* weak_self = self;
  InfinitTemporaryFileManagerCallback callback = ^(BOOL success, NSError* error)
  {
    if (!weak_self)
      return;
    InfinitSendGalleryController* strong_self = weak_self;
    if (success)
    {
      ELLE_TRACE("%s: temporary files copied successfully", strong_self.description.UTF8String);
      return;
    }
    if (error)
    {
      NSString* title = nil;
      NSString* message = nil;
      switch (error.code)
      {
        case InfinitFileSystemErrorNoFreeSpace:
          title = NSLocalizedString(@"Not enough space on your device.", nil);
          message =
            NSLocalizedString(@"Free up some space on your device and try again or send fewer files.", nil);
          break;

        default:
          title = NSLocalizedString(@"Unable to fetch files.", nil);
          message =
            NSLocalizedString(@"Infinit was unable to fetch the files from your gallery. Check that you have some free space and try again.", nil);
          break;
      }
      ELLE_WARN("%s: error copying temporary files, show alert with message: %s",
                strong_self.description.UTF8String, message.UTF8String);
      dispatch_async(dispatch_get_main_queue(), ^
      {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
      });
      [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:strong_self.managed_files];
      strong_self->_managed_files = nil;
    }
  };
  NSMutableArray* difference = [self.last_selection mutableCopy];
  [difference removeObjectsInArray:assets];
  if ([InfinitHostDevice PHAssetClass])
  {
    [manager addPHAssetsLibraryList:assets
                     toManagedFiles:self.managed_files
                    completionBlock:callback];
    for (PHAsset* asset in difference)
      [self.managed_files.remove_assets addObject:asset.localIdentifier];
    for (PHAsset* asset in assets)
      [self.managed_files.remove_assets removeObject:asset.localIdentifier];
  }
  else
  {
    [manager addALAssetsLibraryList:assets
                     toManagedFiles:self.managed_files
                    completionBlock:callback];
    for (ALAsset* asset in difference)
    {
      NSURL* asset_url = [asset valueForProperty:ALAssetPropertyAssetURL];
      [self.managed_files.remove_assets addObject:asset_url];
    }
    for (ALAsset* asset in assets)
    {
      NSURL* asset_url = [asset valueForProperty:ALAssetPropertyAssetURL];
      [self.managed_files.remove_assets removeObject:asset_url];
    }
  }
  if ([segue.identifier isEqualToString:@"gallery_self_only"])
  {
    InfinitSendSelfViewController* view_controller =
      (InfinitSendSelfViewController*)segue.destinationViewController;
    view_controller.managed_files = self.managed_files;
  }
  else if ([segue.identifier isEqualToString:@"send_to_segue"])
  {
    InfinitSendRecipientsController* view_controller =
      (InfinitSendRecipientsController*)segue.destinationViewController;
    view_controller.file_count = assets.count;
    view_controller.managed_files = self.managed_files;
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewOpen
                               method:InfinitUIMethodSendGalleryNext];
  }
  self.last_selection = assets;
}

- (void)configureNextButton
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return;
  CGFloat v_constraint = 0.0f;
  if (self.collection_view.indexPathsForSelectedItems.count == 0)
  {
    self.next_button.enabled = NO;
    v_constraint = -self.next_button.bounds.size.height;
  }
  else
  {
    self.next_button.enabled = YES;
    v_constraint = 0.0f;
  }
  if (self.next_constraint.constant == v_constraint)
    return;
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.next_constraint.constant = v_constraint;
     [self.view layoutIfNeeded];
   } completion:^(BOOL finished)
   {
     if (!finished)
       self.next_constraint.constant = v_constraint;
   }];
}

#pragma mark - Offline Overlay

- (NSArray*)verticalConstraints
{
  NSDictionary* views = @{@"overlay": self.offline_overlay,
                          @"button": self.next_button};
  return [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overlay][button]"
                                                 options:0 
                                                 metrics:nil
                                                   views:views];
}

- (void)filesButtonTapped
{
  // WORKAROUND: For some reason the view is resized when transitioning back which makes the next
  // button show.
  self.next_constraint.constant = - 3.0f * self.next_button.bounds.size.height;
}

#pragma mark - Unwind

- (IBAction)unwindToGalleryViewController:(UIStoryboardSegue*)segue
{}

@end
