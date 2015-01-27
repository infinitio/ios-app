//
//  InfinitFolderModel.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFolderModel.h"

#import "InfinitFileModel.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FolderModel");

@interface InfinitFolderModel ()

@property (nonatomic, readonly) NSString* path;

@end

@implementation InfinitFolderModel

#pragma mark - Init

- (id)initWithPath:(NSString*)path
{
  if (self = [super init])
  {
    _path = path;
    [self fetchMetaData];
    [self fetchFiles];
  }
  return self;
}

- (void)fetchMetaData
{
  NSString* meta_path = [self.path stringByAppendingPathComponent:@".meta"];
  NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:meta_path];
  if (dict == nil)
    return;
  _sender_meta_id = dict[@"sender_meta_id"];
  _sender_name = dict[@"sender_fullname"];
  _ctime = dict[@"ctime"];
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
    [res addObject:file];
  }
  _size = @(total_size);
  _files = [res copy];
  if (self.files.count == 1)
  {
    _name = [self.files.firstObject name];
    _thumbnail = [self.files.firstObject thumbnail];
  }
  else
  {
    _name = [NSString stringWithFormat:NSLocalizedString(@"%lu files", nil), self.files.count];
  }
}

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
}

@end
