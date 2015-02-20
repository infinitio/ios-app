//
//  InfinitFileModel.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFileModel.h"

#import <Gap/InfinitDataSize.h>

@import AVFoundation;

@implementation InfinitFileModel

#pragma mark - Init

- (id)initWithPath:(NSString*)path
           andSize:(NSNumber*)size
{
  if (self = [super init])
  {
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

#pragma mark - NSObject

- (NSString*)description
{
  return [NSString stringWithFormat:@"FileModel (%@): %@",
          self.name, [InfinitDataSize fileSizeStringFrom:self.size]];
}

@end
