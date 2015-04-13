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

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.UploadThumbnailManager");

static CGSize _thumbnail_size = {50.0f, 50.0f};
static CGSize _thumbnail_scaled_size = CGSizeZero;
static NSUInteger _max_thumbnails = 5;

static InfinitUploadThumbnailManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@interface InfinitUploadThumbnailManager ()

/** When we initially send the files, we don't have a Meta ID. We thus need to store the thumbnails
    until we've got it.
 */
@property (nonatomic, readonly) NSMutableDictionary* pending_thumbnails;

@end

@implementation InfinitUploadThumbnailManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _pending_thumbnails = [NSMutableDictionary dictionary];
    [self removeOldThumbnails];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transactionUpdated:) 
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION 
                                               object:nil];
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
               forTransactionWithId:(NSNumber*)id_
{
  @synchronized(self.pending_thumbnails)
  {
    NSMutableArray* thumbnails = [NSMutableArray array];
    if ([PHAsset class])
    {
      PHImageManager* manager = [PHImageManager defaultManager];
      PHImageRequestOptions* options;
      options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
      options.synchronous = YES;
      NSUInteger count = 0;
      for (PHAsset* asset in assets)
      {
        [manager requestImageForAsset:asset
                           targetSize:_thumbnail_scaled_size
                          contentMode:PHImageContentModeAspectFill
                              options:options
                        resultHandler:^(UIImage* result, NSDictionary* info)
         {
           if (result != nil && (result.size.width >= _thumbnail_scaled_size.width))
           {
             CGFloat scale = MAX(result.size.width / _thumbnail_scaled_size.width,
                                 result.size.height / _thumbnail_scaled_size.height);
             CGFloat new_w = result.size.width / scale;
             CGFloat new_h = result.size.height / scale;
             CGRect rect = CGRectMake(0.0f, 0.0f, new_w, new_h);
             UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0f);
             [result drawInRect:rect];
             UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             if (thumbnail != nil)
               [thumbnails addObject:thumbnail];
           }
         }];
        if (++count >= _max_thumbnails)
          break;
      }
    }
    else
    {
      NSUInteger count = 0;
      for (ALAsset* asset in assets)
      {
        UIImage* thumbnail = [UIImage imageWithCGImage:asset.thumbnail
                                                 scale:1.0f
                                           orientation:UIImageOrientationUp];
        if (thumbnail != nil)
        {
          [thumbnails addObject:thumbnail];
          if (++count >= _max_thumbnails)
            break;
        }
      }
    }
    InfinitPeerTransaction* transaction =
      [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
    if (transaction.done)
      [self writeThumbnailsForTransaction:transaction];
    else
      [self.pending_thumbnails setObject:thumbnails forKey:id_];
  }
}

- (void)generateThumbnailsForFiles:(NSArray*)files
              forTransactionWithId:(NSNumber*)id_
{
  @synchronized(self.pending_thumbnails)
  {
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
    if (transaction.done)
      [self writeThumbnailsForTransaction:transaction];
    else
      [self.pending_thumbnails setObject:thumbnails forKey:id_];
  }
}

- (void)removeThumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  [self removeThumbnailFolderForTransactionMetaId:transaction.meta_id];
}

- (NSArray*)thumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
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
  @synchronized(self.pending_thumbnails)
  {
    NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
    InfinitPeerTransaction* transaction =
      [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
    NSArray* thumbnails = [self.pending_thumbnails objectForKey:id_];
    if (thumbnails && thumbnails.count == [self expectedThumbnailsForTransaction:transaction] &&
        transaction.meta_id.length > 0)
    {
      [self writeThumbnailsForTransaction:transaction];
    }
  }
}

- (void)writeThumbnailsForTransaction:(InfinitPeerTransaction*)transaction
{
  NSArray* thumbnails = [self.pending_thumbnails objectForKey:transaction.id_];
  if (thumbnails == nil || thumbnails.count == 0)
    return;
  [self.pending_thumbnails removeObjectForKey:transaction.id_];
  NSString* res_folder = [self thumbnailFolderForTransactionMetaId:transaction.meta_id
                                                            create:YES];
  NSString* res_path = nil;
  NSInteger number_of_files = [self expectedThumbnailsForTransaction:transaction];
  for (NSUInteger i = 0; i < number_of_files; i++)
  {
    res_path = [res_folder stringByAppendingPathComponent:transaction.files[i]];
    [self writeImage:thumbnails[i] toPath:res_path];
  }
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
  [UIImageJPEGRepresentation(image, 1.0f) writeToFile:path
                                              options:NSDataWritingAtomic
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
}

@end
