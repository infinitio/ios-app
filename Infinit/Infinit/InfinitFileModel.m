//
//  InfinitFileModel.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFileModel.h"

#import <Gap/NSNumber+DataSize.h>

@import AVFoundation;

@implementation InfinitFileModel

#pragma mark - Init

- (id)initWithPath:(NSString*)path
           andSize:(NSNumber*)size
         forFolder:(InfinitFolderModel*)folder
{
  if (self = [super init])
  {
    _folder = folder;
    _path = path;
    _size = size;
    _type = [InfinitFilePreview fileTypeForPath:self.path];
    if (self.type == InfinitFileTypeVideo)
    {
      NSURL* url = [NSURL fileURLWithPath:self.path];
      AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
      _duration = CMTimeGetSeconds(asset.duration);
    }
    else
    {
      _duration = 0.0f;
    }
  }
  return self;
}

- (NSString*)name
{
  return self.path.lastPathComponent;
}

- (BOOL)string:(NSString*)string
      contains:(NSString*)search
{
  if (!search.length)
    return YES;
  if ([string rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  return NO;
}

- (BOOL)containsString:(NSString*)string
{
  if ([self string:self.name contains:string])
    return YES;
  return NO;
}

- (BOOL)matchesType:(InfinitFileTypes)type
{
  if (self.type & type)
    return YES;
  return NO;
}

#pragma mark - NSObject

- (NSString*)description
{
  return [NSString stringWithFormat:@"FileModel (%@): %@", self.name, self.size.infinit_fileSize];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:InfinitFileModel.class])
    return NO;
  InfinitFileModel* other = (InfinitFileModel*)object;
  if ([self.path isEqualToString:other.path])
    return YES;
  return NO;
}

@end
