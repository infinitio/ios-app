//
//  InfinitFolderModel.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFolderModel.h"

#import "InfinitFileModel.h"
#import "InfinitHostDevice.h"

#import <Gap/InfinitDirectoryManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FolderModel");

@interface InfinitFolderModel ()

@property (nonatomic, readonly) NSString* path;
@property (nonatomic, readonly) NSMutableDictionary* meta_data;
@property (nonatomic, readonly) NSString* meta_data_path;
@property (nonatomic, readonly) NSString* thumbnail_folder;

@end

@implementation InfinitFolderModel

#pragma mark - Init

- (id)initWithPath:(NSString*)path
{
  if (self = [super init])
  {
    _path = path;
    _id_ = path.lastPathComponent;
    [self fetchMetaData];
    if (self.done)
      [self fetchFiles];
  }
  return self;
}

- (void)fetchMetaData
{
  _meta_data = [NSMutableDictionary dictionaryWithContentsOfFile:self.meta_data_path];
  if (self.meta_data == nil)
    return;
  _ctime = self.meta_data[@"ctime"];
  NSNumber* done_ = self.meta_data[@"done"];
  _done = done_.boolValue;
  _name = self.meta_data[@"name"];
  _sender_name = self.meta_data[@"sender_fullname"];
  _sender_meta_id = self.meta_data[@"sender_meta_id"];
}

- (void)fetchFiles
{
  NSURL* url = [NSURL fileURLWithPath:self.path];
  NSDirectoryEnumerator* enumerator =
    [[NSFileManager defaultManager] enumeratorAtURL:url
                         includingPropertiesForKeys:@[NSURLNameKey,
                                                      NSURLIsDirectoryKey,
                                                      NSURLFileSizeKey]
                                            options:NSDirectoryEnumerationSkipsPackageDescendants
                                       errorHandler:^BOOL(NSURL* url, NSError* error)
  {
    if (error)
    {
      ELLE_ERR("%s: unable to enumerate directory: %s",
               self.description.UTF8String, error.description.UTF8String);
      return NO;
    }
    return YES;
  }];
  NSMutableArray* res = [NSMutableArray array];
  NSUInteger total_size = 0;
  NSNumber* file_size;
  NSNumber* is_directory;
  NSString* url_name;
  for (NSURL* url in enumerator)
  {
    [url getResourceValue:&url_name forKey:NSURLNameKey error:nil];
    if ([url_name isEqualToString:@".meta"])
      continue;
    [url getResourceValue:&is_directory forKey:NSURLIsDirectoryKey error:nil];
    if (is_directory.boolValue)
      continue;

    [url getResourceValue:&file_size forKey:NSURLFileSizeKey error:nil];
    total_size += file_size.unsignedIntegerValue;
    NSString* file_path = url.path;
    InfinitFileModel* file = [[InfinitFileModel alloc] initWithPath:file_path andSize:file_size];
    UIImage* thumbnail;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self thumbnailPathForObject:file]])
    {
      thumbnail = [UIImage imageWithContentsOfFile:[self thumbnailPathForObject:file]];
    }
    else
    {
      thumbnail = [InfinitFilePreview previewForPath:file.path
                                              ofSize:CGSizeMake(50.0f, 50.0f)
                                                crop:YES];
      [self writeImage:thumbnail toPath:[self thumbnailPathForObject:file]];
    }
    file.thumbnail = thumbnail;
    [res addObject:file];
  }
  _size = @(total_size);
  _files = [res copy];
  if (self.files.count == 1)
  {
    if (self.name == nil)
      _name = [self.files.firstObject name];
  }
  else
  {
    if (self.name == nil)
      _name = [NSString stringWithFormat:NSLocalizedString(@"%lu files", nil), self.files.count];
  }
  [self generateThumbnail];
}

- (void)generateThumbnail
{
  if ([[NSFileManager defaultManager] fileExistsAtPath:[self thumbnailPathForObject:self]])
  {
    _thumbnail = [UIImage imageWithContentsOfFile:[self thumbnailPathForObject:self]];
    return;
  }

  if (self.files.count == 1)
  {
    _thumbnail = [self.files.firstObject thumbnail];
  }
  else
  {
    NSMutableArray* thumbs = [NSMutableArray array];
    for (InfinitFileModel* file in self.files)
    {
      if (file.type == InfinitFileTypeImage || file.type == InfinitFileTypeVideo)
      {
        UIImage* thumb = file.thumbnail;
        if (thumb == nil)
          thumb = [UIImage imageNamed:@"icon-mimetype-folder"];
        [thumbs addObject:thumb];
      }
      if (thumbs.count > 3)
        break;
    }
    if (thumbs.count == 0)
    {
      _thumbnail = [UIImage imageNamed:@"icon-mimetype-folder"];
    }
    else
    {
      CGSize thumb_size = CGSizeMake(50.0f, 50.0f);
      CGRect output_rect = CGRectMake(0.0f, 0.0f, thumb_size.width, thumb_size.height);
      UIGraphicsBeginImageContextWithOptions(thumb_size, NO, 0.0f);
      if (thumbs.count == 1)
      {
        UIImage* image = thumbs[0];
        [image drawInRect:output_rect];
      }
      else if (thumbs.count == 2)
      {
        NSUInteger count = 0;
        for (UIImage* image in thumbs)
        {
          CGRect draw_rect = CGRectMake(floor(thumb_size.width / 2.0f) * count,
                                        0.0f,
                                        floor(thumb_size.width / 2.0f),
                                        thumb_size.height);
          CGFloat scale = [InfinitHostDevice screenScale];
          CGImageRef image_ref =
            CGImageCreateWithImageInRect(image.CGImage, CGRectMake(draw_rect.origin.x * scale,
                                                                   draw_rect.origin.y * scale,
                                                                   draw_rect.size.width * scale,
                                                                   draw_rect.size.height * scale));
          UIImage* draw_image = [UIImage imageWithCGImage:image_ref];
          CGImageRelease(image_ref);
          [draw_image drawInRect:draw_rect];
          count++;
        }
        UIBezierPath* line = [UIBezierPath bezierPath];
        [line moveToPoint:CGPointMake(thumb_size.width / 2.0f, 0.0f)];
        [line addLineToPoint:CGPointMake(thumb_size.width / 2.0f, thumb_size.height)];
        [[UIColor whiteColor] set];
        [line stroke];
      }
      else if (thumbs.count == 3)
      {
        for (NSInteger i = 0; i < (thumbs.count - 1); i++)
        {
          UIImage* image = thumbs[i];
          CGRect rect = CGRectMake(0.0f,
                                   (thumb_size.height / 2.0f) * i,
                                   thumb_size.width / 2.0f,
                                   thumb_size.height / 2.0f);
          [image drawInRect:rect];
        }
        UIImage* image = thumbs[2];
        CGRect rect = CGRectMake(thumb_size.width / 2.0f,
                                 0.0f,
                                 thumb_size.width / 2.0f,
                                 thumb_size.height);
        CGImageRef image_ref = CGImageCreateWithImageInRect(image.CGImage, rect);
        image = [UIImage imageWithCGImage:image_ref];
        CGImageRelease(image_ref);
        [image drawInRect:rect];

        [[UIColor whiteColor] set];
        UIBezierPath* v_line = [UIBezierPath bezierPath];
        [v_line moveToPoint:CGPointMake(thumb_size.width / 2.0f, 0.0f)];
        [v_line addLineToPoint:CGPointMake(thumb_size.width / 2.0f, thumb_size.height)];
        [v_line stroke];
        UIBezierPath* h_line = [UIBezierPath bezierPath];
        [h_line moveToPoint:CGPointMake(0.0f, thumb_size.height / 2.0f)];
        [h_line addLineToPoint:CGPointMake(thumb_size.width / 2.0f, thumb_size.height / 2.0f)];
        [h_line stroke];
      }
      else if (thumbs.count == 4)
      {
        for (NSInteger i = 0; i < thumbs.count; i++)
        {
          UIImage* image = thumbs[i];
          CGRect rect = CGRectMake((thumb_size.width / 2.0f) * (i % 2),
                                   (thumb_size.height / 2.0f) * (i > 1 ? 1 : 0),
                                   thumb_size.width / 2.0f,
                                   thumb_size.height / 2.0f);
          [image drawInRect:rect];
        }
        [[UIColor whiteColor] set];
        UIBezierPath* v_line = [UIBezierPath bezierPath];
        [v_line moveToPoint:CGPointMake(thumb_size.width / 2.0f, 0.0f)];
        [v_line addLineToPoint:CGPointMake(thumb_size.width / 2.0f, thumb_size.height)];
        [v_line stroke];
        UIBezierPath* h_line = [UIBezierPath bezierPath];
        [h_line moveToPoint:CGPointMake(0.0f, thumb_size.height / 2.0f)];
        [h_line addLineToPoint:CGPointMake(thumb_size.width, thumb_size.height / 2.0f)];
        [h_line stroke];
      }
      _thumbnail = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
  }
  [self writeImage:self.thumbnail toPath:[self thumbnailPathForObject:self]];
}

#pragma mark - Properties

- (NSArray*)file_paths
{
  NSMutableArray* res = [NSMutableArray array];
  for (InfinitFileModel* file in self.files)
    [res addObject:file.path];
  return [res copy];
}

- (void)setDone:(BOOL)done
{
  _done = done;
  if (done)
    [self fetchFiles];
  [self updateMetaDataObject:@(done) forKey:@"done"];
}

- (void)setName:(NSString*)name
{
  _name = name;
  [self updateMetaDataObject:name forKey:@"name"];
}

- (void)updateMetaDataObject:(id)object
                      forKey:(NSString*)key
{
  @synchronized(self.meta_data)
  {
    self.meta_data[key] = object;
    [self.meta_data writeToFile:self.meta_data_path atomically:YES];
  }
}

#pragma mark - Delete

- (void)deleteFileAtIndex:(NSInteger)index
{
  NSError* error = nil;
  InfinitFileModel* file = self.files[index];
  [[NSFileManager defaultManager] removeItemAtPath:file.path error:&error];
  if (error)
  {
    ELLE_ERR("%s: unable to remove file: %s",
             self.description.UTF8String, error.description.UTF8String);
  }
  NSMutableArray* res = [self.files mutableCopy];
  [res removeObjectAtIndex:index];
  _files = [res copy];
  if (self.files.count == 1)
    self.name = [self.files.firstObject name];
  else
    self.name = [NSString stringWithFormat:NSLocalizedString(@"%lu files", nil), self.files.count];
}

- (void)deleteFolder
{
  NSError* error = nil;
  [[NSFileManager defaultManager] removeItemAtPath:self.path error:&error];
  if (error)
  {
    ELLE_ERR("%s: unable to remove folder: %s",
             self.description.UTF8String, error.description.UTF8String);
  }
  [[NSFileManager defaultManager] removeItemAtPath:self.thumbnail_folder error:&error];
  if (error)
  {
    ELLE_ERR("%s: unable to remove thumbnail folder: %s",
             self.description.UTF8String, error.description.UTF8String);
  }
}

#pragma mark - Search

- (BOOL)string:(NSString*)string
      contains:(NSString*)search
{
  if ([string rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  return NO;
}

- (BOOL)containsString:(NSString*)string
{
  if ([self string:self.name contains:string])
    return YES;
  if ([self string:self.sender_name contains:string])
    return YES;
  for (InfinitFileModel* file in self.files)
  {
    if ([self string:file.name contains:string])
      return YES;
  }
  return NO;
}

#pragma mark - Helpers

- (NSString*)meta_data_path
{
  return [self.path stringByAppendingPathComponent:@".meta"];
}

- (NSString*)thumbnail_folder
{
  NSString* res = [InfinitDirectoryManager sharedInstance].thumbnail_cache_directory;
  return [res stringByAppendingPathComponent:self.id_];
}

- (NSString*)thumbnailPathForObject:(id)object
{
  NSString* res = self.thumbnail_folder;
  if (![[NSFileManager defaultManager] fileExistsAtPath:res])
  {
    [[NSFileManager defaultManager] createDirectoryAtPath:res
                              withIntermediateDirectories:NO 
                                               attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                                                    error:nil];
  }
  if ([object isKindOfClass:InfinitFileModel.class])
  {
    InfinitFileModel* file = (InfinitFileModel*)object;
    res = [res stringByAppendingPathComponent:file.name];
    res = [res stringByAppendingPathExtension:@"jpg"];
  }
  else if ([object isKindOfClass:InfinitFolderModel.class])
  {
    res = [res stringByAppendingPathComponent:@"infinit_folder_thumbnail.jpg"];
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

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitFolderModel* other = (InfinitFolderModel*)object;
  if ([self.id_ isEqualToString:other.id_])
    return YES;
  return NO;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"FolderModel (%@)%@: %@",
          self.id_, self.done ? @" done": @"", self.files];
}

@end
