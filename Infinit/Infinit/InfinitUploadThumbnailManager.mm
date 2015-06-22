//
//  InfinitUploadThumbnailManager.m
//  Infinit
//
//  Created by Christopher Crone on 04/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitUploadThumbnailManager.h"

#import "InfinitFilePreview.h"
#import "InfinitHostDevice.h"

#import <Gap/InfinitDirectoryManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitThreadSafeArray.h>
#import <Gap/InfinitThreadSafeDictionary.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.UploadThumbnailManager");

static CGSize _thumbnail_size = {50.0f, 50.0f};
static CGSize _thumbnail_scaled_size = CGSizeZero;
static NSUInteger _max_thumbnails = 6;

static InfinitUploadThumbnailManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@interface InfinitUploadThumbnailManager ()

/** When we initially send the files, we don't have a Meta ID. We thus need to store the thumbnails
    until we've got it.
 */
@property (nonatomic, readonly) InfinitThreadSafeDictionary* pending_thumbnails;
@property (nonatomic, readonly) ALAssetsLibrary* library;

@end

@implementation InfinitUploadThumbnailManager

@synthesize library = _library;

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _pending_thumbnails = [InfinitThreadSafeDictionary initWithName:NSStringFromClass(self.class)];
    [self removeOldThumbnails];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transactionUpdated:) 
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION 
                                               object:nil];
    CGFloat scale = [InfinitHostDevice screenScale];
    _thumbnail_scaled_size = CGSizeMake(_thumbnail_size.width * scale,
                                        _thumbnail_size.height * scale);
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitUploadThumbnailManager alloc] init];
  });
  return _instance;
}

- (void)removeOldThumbnails
{
  NSString* root_folder = [InfinitDirectoryManager sharedInstance].upload_thumbnail_cache_directory;
  NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:root_folder
                                                                          error:nil];
  InfinitPeerTransaction* transaction = nil;
  for (NSString* folder in contents)
  {
    transaction = [[InfinitPeerTransactionManager sharedInstance] transactionWithMetaId:folder];
    if (!transaction || transaction.archived)
      [self removeThumbnailFolderForTransactionMetaId:folder];
  }
}

#pragma mark - General

- (BOOL)areThumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  NSString* root_folder = [self thumbnailFolderForTransactionMetaId:transaction.meta_id create:NO];
  if ([[NSFileManager defaultManager] fileExistsAtPath:root_folder])
    return YES;
  return NO;
}

- (void)generateThumbnailsForAssets:(NSArray*)assets
             forTransactionsWithIds:(NSArray*)ids
{
  for (NSNumber* id_ in ids)
    [self generateThumbnailsForAssets:assets forTransactionWithId:id_];
}

- (void)generateThumbnailsForAssets:(NSArray*)assets
               forTransactionWithId:(NSNumber*)id_
{
  if (id_.unsignedIntegerValue == 0)
    return;
  __weak InfinitUploadThumbnailManager* weak_self = self;
  NSArray* fetch_assets =
    (assets.count > _max_thumbnails) ? [assets subarrayWithRange:NSMakeRange(0, _max_thumbnails)]
                                     : assets;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    InfinitUploadThumbnailManager* strong_self = weak_self;
    NSString* name = [NSString stringWithFormat:@"UploadThumbnails(%lu)", id_.unsignedIntegerValue];
    InfinitThreadSafeArray* thumbnails = [InfinitThreadSafeArray initWithName:name];
    if ([InfinitHostDevice PHAssetClass])
    {
      for (NSUInteger i = 0; i < fetch_assets.count; i++)
        [thumbnails addObject:[NSNull null]];
      PHImageManager* manager = [PHImageManager defaultManager];
      PHImageRequestOptions* options;
      options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
      PHFetchResult* result = [PHAsset fetchAssetsWithLocalIdentifiers:fetch_assets options:nil];
      [result enumerateObjectsUsingBlock:^(PHAsset* asset, NSUInteger idx, BOOL* stop)
      {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [manager requestImageForAsset:asset
                           targetSize:_thumbnail_scaled_size
                          contentMode:PHImageContentModeAspectFill
                              options:options
                        resultHandler:^(UIImage* result, NSDictionary* info)
         {
           if (result)
           {
             CGFloat scale = MIN(result.size.width / _thumbnail_scaled_size.width,
                                 result.size.height / _thumbnail_scaled_size.height);
             CGFloat new_w = result.size.width / scale;
             CGFloat new_h = result.size.height / scale;
             CGRect rect = CGRectMake(0.0f, 0.0f, new_w, new_h);
             UIGraphicsBeginImageContext(_thumbnail_scaled_size);
             CGRect clip_rect = CGRectMake(floor((_thumbnail_scaled_size.width - new_w) / 2.0f),
                                           floor((_thumbnail_scaled_size.height - new_h) / 2.0f),
                                           new_w,
                                           new_h);
             UIRectClip(clip_rect);
             [result drawInRect:rect];
             UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             if (thumbnail)
             {
               NSUInteger orig_index = [fetch_assets indexOfObject:asset.localIdentifier];
               if (orig_index != NSNotFound)
                 [thumbnails replaceObjectAtIndex:orig_index withObject:thumbnail];
             }
           }
           dispatch_semaphore_signal(sema);
         }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
      }];
    }
    else
    {
      for (NSURL* url in fetch_assets)
      {
        dispatch_semaphore_t thumb_sema = dispatch_semaphore_create(0);
        [self.library assetForURL:url resultBlock:^(ALAsset* asset)
        {
          UIImage* image = [UIImage imageWithCGImage:asset.thumbnail
                                               scale:1.0f
                                         orientation:UIImageOrientationUp];
          CGFloat scale = MIN(image.size.width / _thumbnail_scaled_size.width,
                              image.size.height / _thumbnail_scaled_size.height);
          CGFloat new_w = image.size.width / scale;
          CGFloat new_h = image.size.height / scale;
          CGRect rect = CGRectMake(0.0f, 0.0f, new_w, new_h);
          UIGraphicsBeginImageContext(_thumbnail_scaled_size);
          CGRect clip_rect = CGRectMake(floor((_thumbnail_scaled_size.width - new_w) / 2.0f),
                                        floor((_thumbnail_scaled_size.height - new_h) / 2.0f),
                                        new_w,
                                        new_h);
          UIRectClip(clip_rect);
          [image drawInRect:rect];
          UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
          UIGraphicsEndImageContext();
          if (thumbnail != nil)
            [thumbnails addObject:thumbnail];
          dispatch_semaphore_signal(thumb_sema);
        } failureBlock:^(NSError* error)
        {
          dispatch_semaphore_signal(thumb_sema);
        }];
        dispatch_semaphore_wait(thumb_sema, DISPATCH_TIME_FOREVER);
      }
    }
    InfinitPeerTransaction* transaction =
      [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
    __block BOOL have_null = NO;
    [thumbnails enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
      if (![obj isKindOfClass:UIImage.class])
      {
        ELLE_ERR("%s: null object in thumbnails array", self.description.UTF8String);
        have_null = YES;
        *stop = YES;
      }
    }];
    if (have_null)
      return;
    [strong_self.pending_thumbnails setObject:thumbnails.underlying_array forKey:id_];
    if (transaction.meta_id.length)
      [strong_self writeThumbnailsForTransaction:transaction];
  });
}

- (void)generateThumbnailsForFiles:(NSArray*)files
            forTransactionsWithIds:(NSArray*)ids
{
  for (NSNumber* id_ in ids)
    [self generateThumbnailsForFiles:files forTransactionWithId:id_];
}

- (void)generateThumbnailsForFiles:(NSArray*)files
              forTransactionWithId:(NSNumber*)id_
{
  if (id_.unsignedIntegerValue == 0)
    return;
  NSMutableArray* thumbnails = [NSMutableArray array];
  NSUInteger count = 0;
  for (NSString* file in files)
  {
    UIImage* thumb = [InfinitFilePreview previewForPath:file
                                                 ofSize:_thumbnail_size
                                                   crop:YES];
    if (thumb != nil)
    {
      [thumbnails addObject:thumb];
      if (++count >= _max_thumbnails)
        break;
    }
  }
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction.meta_id.length)
    [self writeThumbnailsForTransaction:transaction];
  else
    [self.pending_thumbnails setObject:thumbnails forKey:id_];
}

- (void)removeThumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  [self removeThumbnailFolderForTransactionMetaId:transaction.meta_id];
}

- (NSArray*)thumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  NSArray* pending_thumbnails = [self.pending_thumbnails objectForKey:transaction.id_];
  if (pending_thumbnails)
  {
    if (transaction.meta_id.length)
      [self writeThumbnailsForTransaction:transaction];
    return pending_thumbnails;
  }
  NSString* root_folder = [self thumbnailFolderForTransactionMetaId:transaction.meta_id create:NO];
  NSMutableArray* res = [NSMutableArray array];
  BOOL generate_thumbnails = YES;
  if ([[NSFileManager defaultManager] fileExistsAtPath:root_folder])
  {
    generate_thumbnails = NO;
    NSError* error = nil;
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:root_folder 
                                                                            error:&error];
    if (error)
    {
      ELLE_WARN("%s: unable to fetch contents of folder: %s",
                self.description.UTF8String, error.description.UTF8String);
      generate_thumbnails = YES;
    }
    else if (contents.count < _max_thumbnails && contents.count != transaction.files.count)
    {
      ELLE_WARN("%s: number of cached thumbnails (%lu) differs from number of transaction files (%lu)",
                self.description.UTF8String, contents.count, transaction.files.count);
      generate_thumbnails = YES;
    }
    NSString* thumb_path = nil;
    if (!generate_thumbnails)
    {
      for (NSString* thumb in contents)
      {
        thumb_path = [root_folder stringByAppendingPathComponent:thumb];
        UIImage* thumbnail = [UIImage imageWithContentsOfFile:thumb_path];
        if (thumbnail == nil)
          generate_thumbnails = YES;
        else
          [res addObject:thumbnail];
      }
    }
  }

  if (generate_thumbnails)
  {
    [res removeAllObjects];
    for (NSString* filename in transaction.files)
      [res addObject:[InfinitFilePreview iconForFilename:filename]];
  }
  return res;
}

#pragma mark - Transaction Updated

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  NSArray* thumbnails = [self.pending_thumbnails objectForKey:id_];
  if (thumbnails && transaction.meta_id.length)
  {
    [self writeThumbnailsForTransaction:transaction];
  }
}

- (void)writeThumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  if (!transaction.meta_id.length)
    return;
  NSArray* thumbnails = [self.pending_thumbnails objectForKey:transaction.id_];
  [self.pending_thumbnails removeObjectForKey:transaction.id_];
  if (!thumbnails.count)
    return;
  NSString* res_folder = [self thumbnailFolderForTransactionMetaId:transaction.meta_id create:YES];
  [thumbnails enumerateObjectsUsingBlock:^(UIImage* thumbnail, NSUInteger i, BOOL* stop)
  {
    if (i < transaction.files.count)
    {
      NSString* res_path = [res_folder stringByAppendingPathComponent:transaction.files[i]];
      [self writeImage:thumbnail toPath:res_path];
    }
  }];
}

#pragma mark - Helpers

- (NSUInteger)expectedThumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  return transaction.files.count > _max_thumbnails ? _max_thumbnails : transaction.files.count;
}

- (NSString*)thumbnailFolderForTransactionMetaId:(NSString*)meta_id
                                          create:(BOOL)create
{
  NSString* res = [InfinitDirectoryManager sharedInstance].upload_thumbnail_cache_directory;
  res = [res stringByAppendingPathComponent:meta_id];
  if (create && ![[NSFileManager defaultManager] fileExistsAtPath:res])
  {
    [[NSFileManager defaultManager] createDirectoryAtPath:res
                              withIntermediateDirectories:NO
                                               attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                                                    error:nil];
  }
  return res;
}

- (void)writeImage:(UIImage*)image
            toPath:(NSString*)path
{
  NSError* error = nil;
  if (image == nil)
  {
    ELLE_ERR("%s: not writing empty thumbnail: %s", self.description.UTF8String, path.UTF8String);
    return;
  }
  [UIImageJPEGRepresentation(image, 1.0f) writeToFile:path
                                              options:0
                                                error:&error];
  if (error)
  {
    ELLE_ERR("%s: unable to write thumbnail to disk: %s",
             self.description.UTF8String, error.description.UTF8String);
  }
}

- (void)removeThumbnailFolderForTransactionMetaId:(NSString*)meta_id
{
  NSError* error = nil;
  NSString* path = [self thumbnailFolderForTransactionMetaId:meta_id create:NO];
  [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
  if (error)
  {
    ELLE_WARN("%s: unable to remove thumbnails from disk: %s",
              self.description.UTF8String, error.description.UTF8String);
  }
}

#pragma mark - Helpers

- (ALAssetsLibrary*)library
{
  static dispatch_once_t _library_token = 0;
  dispatch_once(&_library_token, ^
  {
    _library = [[ALAssetsLibrary alloc] init];
  });
  return _library;
}

@end
