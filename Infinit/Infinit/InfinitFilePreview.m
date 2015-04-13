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
  if (UTTypeConformsTo(file_uti, kUTTypeAudio))
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
  else if (UTTypeConformsTo(file_uti, kUTTypeMovie))
  {
    res = InfinitFileTypeVideo;
  }
  CFRelease(file_uti);
  CFRelease(extension);
  return res;
}

+ (UIImage*)iconForFilename:(NSString*)filename
{
  UIImage* res = nil;
  switch ([InfinitFilePreview fileTypeForPath:filename])
  {
    case InfinitFileTypeAudio:
      res = [UIImage imageNamed:@"icon-mimetype-audio-home"];
      break;
    case InfinitFileTypeDirectory:
      res = [UIImage imageNamed:@"icon-mimetype-folder-home"];
    case InfinitFileTypeImage:
      res = [UIImage imageNamed:@"icon-mimetype-picture-home"];
      break;
    case InfinitFileTypeVideo:
      res = [UIImage imageNamed:@"icon-mimetype-video-home"];
      break;

    case InfinitFileTypeDocument:
    case InfinitFileTypeOther:
    default:
      res = [UIImage imageNamed:@"icon-mimetype-doc"];
      break;
  }
  return res;
}

+ (UIImage*)previewForPath:(NSString*)path
                    ofSize:(CGSize)size
                      crop:(BOOL)crop
{
  __block UIImage* res = nil;
  __block BOOL generated = NO;
  InfinitFileTypes type = [InfinitFilePreview fileTypeForPath:path];
  if (type == InfinitFileTypeAudio)
  {
    res = [UIImage imageNamed:@"icon-mimetype-audio"];
  }
  else if (type == InfinitFileTypeDocument)
  {
    res = [UIImage imageNamed:@"icon-mimetype-doc"];
  }
  else if (type == InfinitFileTypeImage)
  {
    res = [UIImage imageWithContentsOfFile:path];
    generated = YES;
  }
  else if (type == InfinitFileTypeDirectory)
  {
    res = [UIImage imageNamed:@"icon-mimetype-folder"];
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
    res = [UIImage imageNamed:@"icon-mimetype-doc"];
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
  UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
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
