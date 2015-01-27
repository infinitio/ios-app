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
  CFStringRef extension = (__bridge CFStringRef)path.pathExtension;
  CFStringRef file_uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                               extension,
                                                               NULL);
  InfinitFileTypes res = InfinitFileTypeOther;
  if (UTTypeConformsTo(file_uti, kUTTypeAudio))
  {
    res = InfinitFileTypeAudio;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeImage))
  {
    res = InfinitFileTypeImage;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypePDF))
  {
    res = InfinitFileTypePDF;
  }
  else if (UTTypeConformsTo(file_uti, kUTTypeMovie))
  {
    res = InfinitFileTypeVideo;
  }
  CFRelease(file_uti);
  return res;
}

+ (UIImage*)previewForPath:(NSString*)path
                    ofSize:(CGSize)size
                      crop:(BOOL)crop
{
  __block UIImage* res;
  CGSize scaled_size = CGSizeMake(size.width * [InfinitHostDevice screenScale],
                                  size.height * [InfinitHostDevice screenScale]);
  InfinitFileTypes type = [InfinitFilePreview fileTypeForPath:path];
  if (type == InfinitFileTypeImage)
  {
    res = [UIImage imageWithContentsOfFile:path];
  }
  else if (type == InfinitFileTypeVideo)
  {
    NSURL* url = [NSURL fileURLWithPath:path];
    AVURLAsset* asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator* generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = scaled_size;
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
         dispatch_semaphore_signal(thumb_sema);
         return;
       }
       res = [UIImage imageWithCGImage:image];
       dispatch_semaphore_signal(thumb_sema);
     }];
    dispatch_semaphore_wait(thumb_sema, DISPATCH_TIME_FOREVER);
  }
  CGFloat scale;
  if (crop)
  {
    scale = MIN(res.size.width / scaled_size.width,
                res.size.height / scaled_size.height);
  }
  else
  {
    scale = MAX(res.size.width / scaled_size.width,
                res.size.height / scaled_size.height);
  }
  CGFloat new_w = res.size.width / scale;
  CGFloat new_h = res.size.height / scale;
  CGRect rect = CGRectMake(0.0f, 0.0f, new_w, new_h);
  UIGraphicsBeginImageContext(rect.size);
  [res drawInRect:rect];
  res = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  if (crop)
  {
    CGRect crop_rect = CGRectMake((res.size.width - new_w) / 2.0f,
                                  (res.size.height - new_h) / 2.0f,
                                  scaled_size.width,
                                  scaled_size.height);
    CGImageRef cropped_image = CGImageCreateWithImageInRect(res.CGImage, crop_rect);
    res = [UIImage imageWithCGImage:cropped_image];
  }
  return res;
}

@end
