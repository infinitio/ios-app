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
@property (nonatomic, strong) NSMutableDictionary* selectedMedia;
@property(nonatomic, strong) NSMutableArray* assetURLArray;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;

@end

@implementation InfinitMediaCollectionViewController

static NSString * const reuseIdentifier = @"mediaCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[InfCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
  
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/




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
  cell.backgroundColor=[UIColor greenColor];
  
  if([_selectedMedia objectForKey:indexPath])
  {
    cell.checkMark.hidden = NO;
  } else {
    cell.checkMark.hidden = YES;
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
  
  
  if(_selectedMedia == nil)
  {
    _selectedMedia = [[NSMutableDictionary alloc] init];
  }
  
  
  if([_selectedMedia objectForKey:indexPath])
  {
    cell.checkMark.hidden = YES;
    
    [_selectedMedia removeObjectForKey:indexPath];
    
    NSString *buttonString = [NSString stringWithFormat:@"Next (%lu)", (unsigned long)_selectedMedia.allKeys.count];
    [UIView performWithoutAnimation:^ {
      [self.nextButton setTitle:buttonString];
    }];  }
  else
  {
    cell.checkMark.hidden = NO;
    
    [_selectedMedia setObject:indexPath forKey:indexPath];
    
    NSString* buttonString = [NSString stringWithFormat:@"Next (%lu)", (unsigned long)_selectedMedia.allKeys.count];
    
    [UIView performWithoutAnimation:^ {
      [self.nextButton setTitle:buttonString];
    }];
  }
  
  [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}


@end
