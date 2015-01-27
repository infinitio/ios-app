//
//  InfinitFileModel.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFileModel.h"

#import "InfinitHostDevice.h"

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
    _thumbnail = [InfinitFilePreview previewForPath:self.path
                                             ofSize:CGSizeMake(50.0f, 50.0f)
                                               crop:YES];
  }
  return self;
}

- (NSString*)name
{
  return self.path.lastPathComponent;
}

@end
