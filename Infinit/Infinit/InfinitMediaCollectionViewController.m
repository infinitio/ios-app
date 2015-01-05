//
//  InfinitMediaCollectionViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitMediaCollectionViewController.h"

#import "InfCollectionViewCell.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import <Gap/InfinitTemporaryFileManager.h>

@interface InfinitMediaCollectionViewController ()

@property(nonatomic, strong) NSArray* assets;
@property (nonatomic, strong) NSMutableDictionary* selected_media;
@property(nonatomic, strong) NSMutableArray* assetURL_array;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* next_button;

@end

@implementation InfinitMediaCollectionViewController

static NSString* const reuseIdentifier = @"mediaCell";

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationController.navigationBar.clipsToBounds = YES;
  // Uncomment the following line to preserve selection between presentations
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Register cell classes
  [self.collectionView registerClass:[InfCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
  
  
  NSDictionary* lightAttributes =
    @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:17],
      NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:lightAttributes];
  
  NSDictionary* attributes =
    @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold" size:18]};
  [_next_button setTitleTextAttributes:attributes forState:UIControlStateNormal];
  
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  //Makes sure we get the most recent ones even when view has been loaded before.
  [self loadAssets];
}

- (void)loadAssets
{
  _assets = [@[] mutableCopy];
  __block NSMutableArray* tmpAssets = [@[] mutableCopy];
  ALAssetsLibrary* assetsLibrary = [self defaultAssetsLibrary];
  
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup* group, BOOL* stop) {
    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if(result)
      {
        [tmpAssets addObject:result];
      }
    }];
    
    // Can sort these things.  DO THIS. *****
    //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    //self.assets = [tmpAssets sortedArrayUsingDescriptors:@[sort]];
    self.assets = tmpAssets;
    
    [self.collectionView reloadData];
  } failureBlock:^(NSError* error) {
    NSLog(@"Error loading images %@", error);
  }];
}

#pragma mark AssetsLirbary Call

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
  return _assets.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  InfCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
  
  ALAsset* asset = self.assets[self.assets.count - 1 - indexPath.row];
  UIImage* image = [[UIImage alloc] init];
  CGFloat scale  = 1;
  
  if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
  {
    
    if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty) {
      NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:@"mm:ss"];
      
      cell.durationLabel.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]]];
      [cell.contentView addSubview:cell.durationLabel];
      
    }
    
    
    UIImage* thumbnail = [UIImage imageWithCGImage:[asset thumbnail]
                                             scale:scale
                                       orientation:UIImageOrientationUp];
    
    image = thumbnail;
    
  }
  
  if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)
  {
    image = [UIImage imageWithCGImage:[asset thumbnail]
                                scale:scale
                          orientation:UIImageOrientationUp];
  }
  
  cell.imageView.image = image;
  

  if([_selected_media objectForKey:indexPath])
  {
    cell.checkMark.hidden = NO;
    cell.blackLayer.hidden = NO;
  } else {
    cell.checkMark.hidden = YES;
    cell.blackLayer.hidden = YES;
  }
 
  
  
  return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  return CGSizeMake(104, 104);
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsMake(0, 0, 0, 0);
  
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 4.0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 4.0;
}

# pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  //Redraw The Image as blurry, and put a check mark on it.
  InfCollectionViewCell* cell = (InfCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
  
  [self.collectionView bringSubviewToFront:cell];

  [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    cell.contentView.transform = CGAffineTransformMakeScale(.75, .75);
  } completion:^(BOOL finished){
    // do something once the animation finishes, put it here
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      cell.contentView.transform = CGAffineTransformMakeScale(1.25, 1.25);
    } completion:^(BOOL finished){
      // do something once the animation finishes, put it here
      [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cell.contentView.transform = CGAffineTransformMakeScale(.9, .9);
      } completion:^(BOOL finished){
        // do something once the animation finishes, put it here
        [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
          cell.contentView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        } completion:^(BOOL finished) {
          
          [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.contentView.transform = CGAffineTransformIdentity;
          } completion:nil];
        }];
      }];
    }];
  }];
    

  
  
  if(_selected_media == nil)
  {
    _selected_media = [[NSMutableDictionary alloc] init];
  }
  
  
  if([_selected_media objectForKey:indexPath])
  {
    cell.checkMark.hidden = YES;
    cell.blackLayer.hidden = YES;
    
    [_selected_media removeObjectForKey:indexPath];
    
    NSString* buttonString = [NSString stringWithFormat:@"Next (%lu)", (unsigned long)_selected_media.allKeys.count];
    [UIView performWithoutAnimation:^ {
      [self.next_button setTitle:buttonString];
    }];
  }
  else
  {
    cell.checkMark.hidden = NO;
    cell.blackLayer.hidden = NO;

    [_selected_media setObject:indexPath forKey:indexPath];
    
    NSString* buttonString = [NSString stringWithFormat:@"Next (%lu)", (unsigned long)_selected_media.allKeys.count];
    
    [UIView performWithoutAnimation:^ {
      [self.next_button setTitle:buttonString];
    }];
  }
  
  [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (IBAction)backButtonClicked:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([segue.identifier isEqualToString:@"send2Segue"])
  {
    
  }
}

-(BOOL)prefersStatusBarHidden
{
  return YES;
}


@end
