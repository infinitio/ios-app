//
//  InfinitGalleryManager.m
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitGalleryManager.h"

#import "InfinitApplicationSettings.h"
#import "InfinitConstants.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFilePreview.h"
#import "InfinitHostDevice.h"

#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <Photos/Photos.h>

#import <Gap/InfinitPeerTransactionManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.GalleryManager");

@interface InfinitGalleryManager ()

@property (nonatomic, readonly) ALAssetsLibrary* library;
@property (nonatomic, readonly) dispatch_once_t library_token;

@end

static dispatch_once_t _instance_token = 0;
static InfinitGalleryManager* _instance = nil;

@implementation InfinitGalleryManager

@synthesize library = _library;

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    self.autosave = [InfinitApplicationSettings sharedInstance].autosave_to_gallery;
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
    _instance = [[self alloc] init];
  });
  return _instance;
}

#pragma mark - Public

- (void)setAutosave:(BOOL)autosave
{
  @synchronized(self)
  {
    if (self.autosave == autosave)
      return;
    _autosave = autosave;
    [InfinitApplicationSettings sharedInstance].autosave_to_gallery = autosave;
    if (autosave)
    {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(transactionUpdated:)
                                                   name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                                 object:nil];
    }
    else
    {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
  }
}

+ (void)saveToGallery:(NSArray*)paths
{
  [[self sharedInstance] saveToGallery:paths];
}

- (void)saveToGallery:(NSArray*)paths
{
  if (paths.count == 0 || ![self haveGalleryAccess])
    return;
  if ([InfinitHostDevice PHAssetClass])
  {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
       PHFetchResult* collections = [PHCollection fetchTopLevelUserCollectionsWithOptions:nil];
       __block PHAssetCollection* collection = nil;
       [collections enumerateObjectsUsingBlock:^(PHAssetCollection* user_collection,
                                                 NSUInteger index,
                                                 BOOL* stop)
        {
          if ([user_collection.localizedTitle isEqualToString:kInfinitAlbumName])
            collection = user_collection;
        }];
       PHAssetCollectionChangeRequest* collection_request = nil;
       if (!collection)
       {
         collection_request =
           [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kInfinitAlbumName];
       }
       else
       {
         collection_request =
           [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
       }
       NSMutableArray* assets = [NSMutableArray array];
       for (NSString* path in paths)
       {
         InfinitFileTypes type = [InfinitFilePreview fileTypeForPath:path];
         PHAssetChangeRequest* asset_request = nil;
         if (type == InfinitFileTypeImage)
         {
           NSURL* url = [NSURL fileURLWithPath:path];
           asset_request = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
           if (asset_request)
             [assets addObject:asset_request.placeholderForCreatedAsset];
         }
         else if (type == InfinitFileTypeVideo)
         {
           NSURL* url = [NSURL fileURLWithPath:path];
           asset_request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
           if (asset_request)
             [assets addObject:asset_request.placeholderForCreatedAsset];
         }
       }
       [collection_request addAssets:assets];
     } completionHandler:NULL];
  }
  else
  {
    for (NSString* path in paths)
    {
      InfinitFileTypes type = [InfinitFilePreview fileTypeForPath:path];
      if (type == InfinitFileTypeImage)
      {
        [self.library saveImageData:[NSData dataWithContentsOfFile:path]
                            toAlbum:kInfinitAlbumName
                           metadata:nil
                         completion:^(NSURL* assetURL, NSError* error)
         {
           if (error)
           {
             ELLE_ERR("%s: unable to save image: %s", self.description.UTF8String, path.UTF8String);
           }
         } failure:^(NSError* error)
         {
           if (error)
           {
             ELLE_ERR("%s: unable to save image: %s", self.description.UTF8String, path.UTF8String);
           }
         }];
      }
      else if (type == InfinitFileTypeVideo)
      {
        [self.library saveVideo:[NSURL URLWithString:path]
                        toAlbum:kInfinitAlbumName
                     completion:^(NSURL* assetURL, NSError* error)
         {
           if (error)
           {
             ELLE_ERR("%s: unable to save video: %s", self.description.UTF8String, path.UTF8String);
           }
         } failure:^(NSError* error)
         {
           if (error)
           {
             ELLE_ERR("%s: unable to save video: %s", self.description.UTF8String, path.UTF8String);
           }
         }];
      }
    }
  }
}

#pragma mark - Transaction Updates

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  NSNumber* status_num = notification.userInfo[kInfinitTransactionStatus];
  gap_TransactionStatus status = static_cast<gap_TransactionStatus>([status_num integerValue]);
  InfinitPeerTransaction* transaction = [InfinitPeerTransactionManager transactionWithId:id_];
  if (!transaction)
    return;
  if (transaction.to_device && status == gap_transaction_finished)
  {
    InfinitDownloadFolderManager* manager = [InfinitDownloadFolderManager sharedInstance];
    InfinitFolderModel* folder = [manager completedFolderForTransactionMetaId:transaction.meta_id];
    [self saveToGallery:folder.file_paths];
  }
}

#pragma mark - Helpers

- (ALAssetsLibrary*)library
{
  dispatch_once(&_library_token, ^
  {
    _library = [[ALAssetsLibrary alloc] init];
  });
  return _library;
}

- (BOOL)haveGalleryAccess
{
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)
    return YES;
  return NO;
}

@end
