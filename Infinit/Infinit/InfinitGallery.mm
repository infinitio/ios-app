//
//  InfinitGallery.m
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitGallery.h"

#import "InfinitConstants.h"
#import "InfinitFilePreview.h"

#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <Photos/Photos.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.Gallery");

@interface InfinitGallery ()

@property (nonatomic, strong) ALAssetsLibrary* library;

@end

static dispatch_once_t _instance_token = 0;
static InfinitGallery* _instance = nil;

@implementation InfinitGallery

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _library = [[ALAssetsLibrary alloc] init];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitGallery alloc] init];
  });
  return _instance;
}

- (BOOL)haveGalleryAccess
{
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)
    return YES;
  return NO;
}

- (void)saveToGallery:(NSArray*)paths
{
  if (paths.count == 0 || ![self haveGalleryAccess])
    return;
  if ([PHAsset class])
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
    }
  }
}

+ (void)saveToGallery:(NSArray*)paths
{
  [[InfinitGallery sharedInstance] saveToGallery:paths];
}

@end
