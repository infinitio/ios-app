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
#import "ISO6709Location.h"
#import <Photos/Photos.h>

#import <Gap/InfinitPeerTransactionManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.GalleryManager");

@interface InfinitGalleryManager ()

@property (atomic, readonly) NSDateFormatter* gps_date_formatter;
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
    _gps_date_formatter = [[NSDateFormatter alloc] init];
    self.gps_date_formatter.dateFormat = @"yyyy:MM:dd HH:mm:ss";
    self.gps_date_formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
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
  ELLE_LOG("%s: saving %lu items to the gallery", self.description.UTF8String, paths.count);
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
           {
             NSData* image_data = [NSData dataWithContentsOfFile:path];
             CGImageSourceRef source =
              CGImageSourceCreateWithData((__bridge CFDataRef)image_data, NULL);
             NSDictionary* metadata =
              CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
             CFRelease(source);
             NSDictionary* gps_data = metadata[(__bridge NSString*)kCGImagePropertyGPSDictionary];
             if (gps_data)
             {
               ELLE_DEBUG("%s: found EXIF GPS data, adding to asset", self.description.UTF8String);
               NSDate* gps_date = [self dateFromDictionary:gps_data];
               if (gps_date)
                 asset_request.creationDate = gps_date;
               CLLocation* gps_location = [self locationFromDictionary:gps_data];
               if (gps_location)
                 asset_request.location = gps_location;
             }
             [assets addObject:asset_request.placeholderForCreatedAsset];
           }
         }
         else if (type == InfinitFileTypeVideo)
         {
           NSURL* url = [NSURL fileURLWithPath:path];
           asset_request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
           AVURLAsset* meta_asset = [AVURLAsset assetWithURL:url];
           NSArray<AVMetadataItem*>* meta_data = meta_asset.metadata;
           for (AVMetadataItem* item in meta_data)
           {
             if ([item.identifier isEqualToString:AVMetadataIdentifierQuickTimeUserDataCreationDate])
             {
               asset_request.creationDate = item.dateValue;
             }
           }
           for (AVMetadataItem* item in meta_data)
           {
             if ([item.identifier isEqualToString:AVMetadataIdentifierQuickTimeUserDataLocationISO6709])
             {
               if (![item.value isKindOfClass:NSString.class])
                 break;
               NSString* location_str = (NSString*)item.value;
               if (location_str.length)
               {
                 CLLocationCoordinate2D coord = ISO6709Location_coordinateFromString(location_str);
                 if (CLLocationCoordinate2DIsValid(coord))
                 {
                   // FIXME: Get altitude from location string.
                   asset_request.location =
                    [[CLLocation alloc] initWithCoordinate:coord
                                                  altitude:0
                                        horizontalAccuracy:0
                                          verticalAccuracy:0
                                                 timestamp:asset_request.creationDate];;
                 }
               }
             }
           }
           if (asset_request)
             [assets addObject:asset_request.placeholderForCreatedAsset];
         }
         else
         {
           if (path.lastPathComponent.length)
           {
             ELLE_DEBUG("%s: item is not an image or video: %s", self.description.UTF8String,
                        path.lastPathComponent.UTF8String);
           }
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
    __weak InfinitGalleryManager* weak_self = self;
    ELLE_TRACE("%s: autosaving files to gallery", self.description.UTF8String);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^
    {
      InfinitDownloadFolderManager* manager = [InfinitDownloadFolderManager sharedInstance];
      InfinitFolderModel* folder = [manager completedFolderForTransactionMetaId:transaction.meta_id];
      [weak_self saveToGallery:folder.file_paths];
    });
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

- (NSDate*)dateFromDictionary:(NSDictionary*)dict
{
  NSString* gps_time_str = [NSString stringWithFormat:@"%@ %@",
                            dict[(__bridge NSString*)kCGImagePropertyGPSDateStamp],
                            dict[(__bridge NSString*)kCGImagePropertyGPSTimeStamp]];
  NSDate* gps_date = [self.gps_date_formatter dateFromString:gps_time_str];
  return gps_date;
}

- (double)doubleForKey:(CFStringRef)key
                  dict:(NSDictionary*)dict
{
  if (![dict.allKeys containsObject:(__bridge NSString*)key])
    return 0.0f;
  return [dict[(__bridge NSString*)key] doubleValue];
}

- (CLLocation*)locationFromDictionary:(NSDictionary*)dict
{
  if (![dict.allKeys containsObject:(__bridge NSString*)kCGImagePropertyGPSLatitude] ||
      ![dict.allKeys containsObject:(__bridge NSString*)kCGImagePropertyGPSLongitude])
    return nil;
  CLLocationCoordinate2D coords;
  coords.latitude = [self doubleForKey:kCGImagePropertyGPSLatitude dict:dict] * ([dict[(__bridge NSString*)kCGImagePropertyGPSLatitudeRef] isEqualToString:@"S"] ? -1.0f : 1.0f);
  coords.longitude = [self doubleForKey:kCGImagePropertyGPSLongitude dict:dict] * ([dict[(__bridge NSString*)kCGImagePropertyGPSLongitudeRef] isEqualToString:@"W"] ? -1.0f : 1.0f);
  NSDate* date = [self dateFromDictionary:dict];
  if (!date)
    return nil;
  return [[CLLocation alloc] initWithCoordinate:coords
                                       altitude:[self doubleForKey:kCGImagePropertyGPSAltitude dict:dict]
                             horizontalAccuracy:[self doubleForKey:kCGImagePropertyGPSHPositioningError dict:dict]
                               verticalAccuracy:0.0f
                                         course:[self doubleForKey:kCGImagePropertyGPSImgDirection dict:dict]
                                          speed:[self doubleForKey:kCGImagePropertyGPSSpeed dict:dict]
                                      timestamp:[self dateFromDictionary:dict]];
}

@end
