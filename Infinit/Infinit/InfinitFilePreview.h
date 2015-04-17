//
//  InfinitFilePreview.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, InfinitFileTypes)
{
  InfinitFileTypeArchive      = 1 << 0,
  InfinitFileTypeAudio        = 1 << 1,
  InfinitFileTypeDirectory    = 1 << 2,
  InfinitFileTypeDocument     = 1 << 3,
  InfinitFileTypeIllustrator  = 1 << 4,
  InfinitFileTypeImage        = 1 << 5,
  InfinitFileTypePhotoshop    = 1 << 6,
  InfinitFileTypePresentation = 1 << 7,
  InfinitFileTypeSketch       = 1 << 8,
  InfinitFileTypeSpreadsheet  = 1 << 9,
  InfinitFileTypeVideo        = 1 << 10,

  InfinitFileTypeOther        = 1 << 11,
  InfinitFileTypeAll          = NSUIntegerMax,
};

@interface InfinitFilePreview : NSObject

+ (InfinitFileTypes)fileTypeForPath:(NSString*)path;

+ (UIImage*)iconForFilename:(NSString*)filename;

+ (UIImage*)previewForPath:(NSString*)path
                    ofSize:(CGSize)size
                      crop:(BOOL)crop;

@end
