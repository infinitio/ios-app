//
//  InfinitFilePreview.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilePreview.h"

#import "InfinitHostDevice.h"

@import AVFoundation;
@import MobileCoreServices;

@implementation InfinitFilePreview

+ (InfinitFileTypes)fileTypeForPath:(NSString*)path
{
  CFStringRef extension = (__bridge_retained CFStringRef)path.pathExtension;
  CFStringRef file_uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                               extension,
                                                               NULL);
  InfinitFileTypes res = InfinitFileTypeOther;
  if (UTTypeConformsTo(file_uti, CFSTR("com.adobe.illustrator.ai-image")))
  {
    res = InfinitFileTypeIllustrator;
  }
  else if (UTTypeConformsTo(file_uti, CFSTR("com.adobe.photoshop-image")))
  {
    res = InfinitFileTypePhotoshop;
  }
  else if (UTTypeConformsTo(file_uti, CFSTR("com.microsoft.excel.xls")) ||
           UTTypeConformsTo(file_uti, CFSTR("com.apple.iwork.numbers.numbers")))
  {
    res = InfinitFileTypeSpreadsheet;
  }
  else if (UTTypeConformsTo(file_uti, CFSTR("com.microsoft.powerpoint")) ||
           UTTypeConformsTo(file_uti, CFSTR("com.apple.iwork.keynote.key")))
  {
    res = InfinitFileTypePresentation;
  }
  else if (UTTypeConformsTo(file_uti, CFSTR("com.bohemiancoding.sketch.drawing.single")) ||
           UTTypeConformsTo(file_uti, CFSTR("com.bohemiancoding.sketch.drawing")))
  {
    res = InfinitFileTypeSketch;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeArchive))
  {
    res = InfinitFileTypeArchive;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeAudio))
  {
    res = InfinitFileTypeAudio;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeFolder))
  {
    res = InfinitFileTypeDirectory;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypePDF) ||
           UTTypeConformsTo(file_uti, kUTTypeText))
  {
    res = InfinitFileTypeDocument;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeImage))
  {
    res = InfinitFileTypeImage;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeAudiovisualContent))
  {
    res = InfinitFileTypeVideo;
  }
  CFRelease(file_uti);
  CFRelease(extension);
  return res;
}

+ (UIImage*)iconForFilename:(NSString*)filename
{
  switch ([InfinitFilePreview fileTypeForPath:filename])
  {
    case InfinitFileTypeArchive:
      return [UIImage imageNamed:@"icon-mimetype-archive-home"];
    case InfinitFileTypeAudio:
      return [UIImage imageNamed:@"icon-mimetype-audio-home"];
    case InfinitFileTypeDirectory:
      return [UIImage imageNamed:@"icon-mimetype-folder-home"];
    case InfinitFileTypeIllustrator:
      return [UIImage imageNamed:@"icon-mimetype-illustrator-home"];
    case InfinitFileTypeImage:
      return [UIImage imageNamed:@"icon-mimetype-picture-home"];
    case InfinitFileTypePhotoshop:
      return [UIImage imageNamed:@"icon-mimetype-photoshop-home"];
    case InfinitFileTypeSketch:
      return [UIImage imageNamed:@"icon-mimetype-sketch-home"];
    case InfinitFileTypeSpreadsheet:
    case InfinitFileTypePresentation:
      return [UIImage imageNamed:@"icon-mimetype-powerpoint-home"];
    case InfinitFileTypeVideo:
      return [UIImage imageNamed:@"icon-mimetype-video-home"];

    case InfinitFileTypeDocument:
    case InfinitFileTypeOther:
    default:
      return [UIImage imageNamed:@"icon-mimetype-doc-home"];
  }
}

+ (UIImage*)previewForPath:(NSString*)path
                    ofSize:(CGSize)size
                      crop:(BOOL)crop
{
  __block UIImage* res = nil;
  __block BOOL generated = NO;
  InfinitFileTypes type = [InfinitFilePreview fileTypeForPath:path];
  if (type == InfinitFileTypeImage)
  {
    // Ensure we render files with @2x correctly.
    NSData* image_data = [NSData dataWithContentsOfFile:path];
    res = [UIImage imageWithData:image_data scale:1.0f];
    generated = YES;
  }
  else if (type == InfinitFileTypeVideo)
  {
    NSURL* url = [NSURL fileURLWithPath:path];
    AVURLAsset* asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator* generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CGFloat max_dim = MAX(size.width, size.height);
    generator.maximumSize = CGSizeMake(max_dim * [InfinitHostDevice screenScale],
                                       max_dim * [InfinitHostDevice screenScale]);
    CMTime time = CMTimeMake(1, 1);
    dispatch_semaphore_t thumb_sema = dispatch_semaphore_create(0);
    [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:time]]
                                    completionHandler:^(CMTime requestedTime,
                                                        CGImageRef image,
                                                        CMTime actualTime,
                                                        AVAssetImageGeneratorResult result,
                                                        NSError* error)
     {
       if (error)
       {
         NSLog(@"unable to generate video thumbnail: %@", error);
         res = [UIImage imageNamed:@"icon-mimetype-video-home"];
       }
       else
       {
         res = [UIImage imageWithCGImage:image];
         generated = YES;
       }
       dispatch_semaphore_signal(thumb_sema);
     }];
    dispatch_semaphore_wait(thumb_sema, DISPATCH_TIME_FOREVER);
  }
  else
  {
    res = [self iconForFilename:path.lastPathComponent];
  }
  if (!generated)
    return res;
  CGFloat scale;
  if (crop)
  {
    scale = MIN(CGImageGetWidth(res.CGImage) / size.width,
                CGImageGetHeight(res.CGImage) / size.height);
  }
  else
  {
    scale = MAX(CGImageGetWidth(res.CGImage) / size.width,
                CGImageGetHeight(res.CGImage) / size.height);
  }
  CGSize new_size = CGSizeMake(floor(res.size.width / scale), floor(res.size.height / scale));
  if (crop)
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
  else
    UIGraphicsBeginImageContextWithOptions(new_size, YES, 0.0f);
  CGRect rect = CGRectMake(0.0f, 0.0f, new_size.width, new_size.height);
  if (crop)
  {
    rect = CGRectMake(floor((size.width - new_size.width) / 2.0f),
                      floor((size.height - new_size.height) / 2.0f),
                      new_size.width,
                      new_size.height);
    UIRectClip(rect);
  }
  [res drawInRect:rect];
  res = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return res;
}

@end
