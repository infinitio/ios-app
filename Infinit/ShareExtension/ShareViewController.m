//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Christopher Crone on 07/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "ShareViewController.h"

#import "InfinitColor.h"
#import "InfinitConstants.h"
#import "InfinitProgressView.h"

@import MobileCoreServices;

@interface ShareViewController ()

@property (nonatomic, weak) IBOutlet UIView* background_view;
@property (nonatomic, weak) IBOutlet UIButton* cancel_button;
@property (nonatomic, weak) IBOutlet UILabel* message_label;
@property (nonatomic, weak) IBOutlet UIView* message_view;
@property (nonatomic, weak) IBOutlet UIButton* ok_button;
@property (nonatomic, weak) IBOutlet InfinitProgressView* progress_view;

@property (nonatomic, readonly) NSMutableArray* item_paths;

@property (nonatomic, readonly) NSString* files_path;
@property (nonatomic, readonly) uint64_t free_space;
@property (nonatomic, readonly) NSString* root_path;

@end

@implementation ShareViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  CGFloat corner_radius = 5.0f;
  self.message_view.layer.cornerRadius = corner_radius;
  self.message_view.layer.masksToBounds = NO;
  self.message_view.layer.shadowOpacity = 0.5f;
  self.message_view.layer.shadowRadius = 5.0f;
  self.message_view.layer.shadowColor = [UIColor blackColor].CGColor;
  self.message_view.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
  self.message_view.layer.shadowPath =
    [UIBezierPath bezierPathWithRoundedRect:self.message_view.bounds cornerRadius:5.0f].CGPath;

  self.cancel_button.showsTouchWhenHighlighted = YES;

  UIBezierPath* bottom_mask = [UIBezierPath bezierPath];
  CGFloat w = self.message_view.bounds.size.width;
  CGFloat h = 50.0f;
  [bottom_mask moveToPoint:CGPointMake(0.0f, 0.0f)];
  [bottom_mask addLineToPoint:CGPointMake(w, 0.0f)];
  [bottom_mask addLineToPoint:CGPointMake(w, h - corner_radius)];
  [bottom_mask addArcWithCenter:CGPointMake(w - corner_radius, h - corner_radius)
                         radius:corner_radius
                     startAngle:0.0f
                       endAngle:M_PI_2
                      clockwise:YES];
  [bottom_mask addLineToPoint:CGPointMake(corner_radius, h)];
  [bottom_mask addArcWithCenter:CGPointMake(corner_radius, h - corner_radius)
                         radius:corner_radius 
                     startAngle:M_PI_2
                       endAngle:M_PI
                      clockwise:YES];
  [bottom_mask closePath];
  CAShapeLayer* mask_layer = [CAShapeLayer layer];
  mask_layer.path = bottom_mask.CGPath;
  mask_layer.fillColor = [UIColor blackColor].CGColor;
  self.ok_button.layer.mask = mask_layer;
  self.ok_button.showsTouchWhenHighlighted = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.background_view.alpha = 0.0f;
  self.ok_button.enabled = YES;
  CGFloat screen_h = [UIScreen mainScreen].bounds.size.height;
  self.message_view.transform =
    CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
  self.message_view.alpha = 0.0f;
  self.cancel_button.alpha = 0.0f;
  self.cancel_button.enabled = NO;
  NSString* text = NSLocalizedString(@"Your files are being copied\nto Infinit...", nil);
  NSAttributedString* message =
    [[NSAttributedString alloc] initWithString:text attributes:[self textAttributesBold:NO]];
  self.message_label.attributedText = message;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  NSExtensionItem* item = self.extensionContext.inputItems.firstObject;
  if (self.item_paths == nil)
    _item_paths = [NSMutableArray array];
  for (NSItemProvider* provider in item.attachments)
  {
    if ([provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeData])
    {
      [provider loadItemForTypeIdentifier:(NSString*)kUTTypeData
                                  options:nil
                        completionHandler:^(NSURL* url, NSError* error)
       {
         if (!error)
         {
           [self.item_paths addObject:url.path];
         }
       }];
    }
  }
  [UIView animateWithDuration:0.4f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
  {
    self.background_view.alpha = 1.0f;
  } completion:^(BOOL finished)
  {
    self.background_view.alpha = 1.0f;
  }];
  [UIView animateWithDuration:0.3f
                        delay:0.2f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.cancel_button.alpha = 1.0f;
     self.message_view.alpha = 1.0f;
     self.message_view.transform = CGAffineTransformIdentity;
   } completion:^(BOOL finished)
   {
     self.cancel_button.alpha = 1.0f;
     self.message_view.alpha = 1.0f;
     self.message_view.transform = CGAffineTransformIdentity;
     self.progress_view.animate_progress = YES;
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
     {
       NSString* text = nil;
       NSRange bold_range = NSMakeRange(NSNotFound, 0);
       UIImage* image = nil;
       if ([self copyFiles])
       {
         image = [UIImage imageNamed:@"icon-extension-check"];
         text = NSLocalizedString(@"Done!\nOpen Infinit to send them.", nil);
         bold_range = [text rangeOfString:NSLocalizedString(@"Done!", nil)];
       }
       else
       {
         image = [UIImage imageNamed:@"icon-extension-error"];
         text = NSLocalizedString(@"Oops!\nNot enough space.", nil);
         bold_range = [text rangeOfString:NSLocalizedString(@"Oops!", nil)];
       }
       NSMutableAttributedString* message =
         [[NSMutableAttributedString alloc] initWithString:text
                                                attributes:[self textAttributesBold:NO]];
       if (bold_range.location != NSNotFound)
         [message setAttributes:[self textAttributesBold:YES] range:bold_range];
       dispatch_async(dispatch_get_main_queue(), ^
       {
         self.progress_view.image = image;
         self.cancel_button.enabled = YES;
         self.message_label.attributedText = message;
       });
     });
   }];
}

#pragma mark - File Handling

- (void)deleteFiles
{
  NSFileManager* manager = [NSFileManager defaultManager];
  NSArray* contents = [manager contentsOfDirectoryAtPath:self.files_path error:nil];
  for (NSString* file in contents)
  {
    NSString* path = [self.files_path stringByAppendingPathComponent:file];
    [manager removeItemAtPath:path error:nil];
  }
}

- (BOOL)copyFiles
{
  if ([self sizeOfFiles:self.item_paths] > self.free_space)
    return NO;

  for (NSString* path in self.item_paths)
  {
    NSError* error = nil;
    NSString* destination_path =
      [self.files_path stringByAppendingPathComponent:path.lastPathComponent];
    if ([path.lastPathComponent isEqualToString:@"FullSizeRender.jpg"])
    {
      NSString* new_filename = nil;
      NSArray* components = [path componentsSeparatedByString:@"/"];
      for (NSString* component in components)
      {
        if ([component containsString:@"IMG"])
        {
          new_filename = [component stringByAppendingString:@".JPG"];
          break;
        }

      }
      if (new_filename)
        destination_path = [self.files_path stringByAppendingPathComponent:new_filename];
    }
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:destination_path error:&error];
    if (error)
    {
      NSLog(@"Unable to copy %@ to %@: %@", path, destination_path, error);
    }
  }
  return YES;
}

#pragma mark - Button Handling

- (void)doneAnimationWithCopy:(BOOL)copy
{
  self.progress_view.animate_progress = NO;
  CGFloat screen_h = [UIScreen mainScreen].bounds.size.height;
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.cancel_button.alpha = 0.0f;
     self.message_view.alpha = 0.0f;
     self.message_view.transform =
       CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
   } completion:^(BOOL finished)
   {
     self.cancel_button.alpha = 0.0f;
     self.message_view.alpha = 0.0f;
     self.message_view.transform =
       CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
   }];
  [UIView animateWithDuration:0.4f
                        delay:0.2f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^
   {
     self.background_view.alpha = 0.0f;
   } completion:^(BOOL finished)
   {
     self.background_view.alpha = 0.0f;
     if (copy)
     {
       [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
     }
     else
     {
       [self.extensionContext cancelRequestWithError:nil];
     }
   }];
}

- (IBAction)cancelTapped:(id)sender
{
  [self deleteFiles];
  [self doneAnimationWithCopy:NO];
}

- (IBAction)okTapped:(id)sender
{
  self.ok_button.enabled = NO;
  self.progress_view.animate_progress = YES;
  [self doneAnimationWithCopy:YES];
}

#pragma mark - Helpers

- (NSDictionary*)textAttributesBold:(BOOL)bold
{
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSTextAlignmentCenter;
  UIFont* font = nil;
  if (bold)
    font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
  else
    font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
  return @{NSFontAttributeName: font,
           NSParagraphStyleAttributeName: para,
           NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73]};
}

- (NSString*)files_path
{
  NSString* res = [self.root_path stringByAppendingPathComponent:@"files"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:res])
  {
    [[NSFileManager defaultManager] createDirectoryAtPath:res
                              withIntermediateDirectories:YES 
                                               attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                                                    error:nil];
  }
  return res;
}

- (NSString*)root_path
{
  NSFileManager* manager = [NSFileManager defaultManager];
  NSURL* shared_url =
    [manager containerURLForSecurityApplicationGroupIdentifier:kInfinitAppGroupName];
  NSString* res = [shared_url.path stringByAppendingPathComponent:@"extension"];
  if (![manager fileExistsAtPath:res])
  {
    [manager createDirectoryAtPath:res
       withIntermediateDirectories:YES
                        attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                             error:nil];
  }
  return res;
}

- (uint64_t)sizeOfFiles:(NSArray*)files
{
  uint64_t res = 0;
  for (NSString* path in files)
  {
    NSError* error = nil;
    NSDictionary* dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                          error:&error];
    if (dict && !error)
    {
      NSNumber* f_size = dict[NSFileSize];
      res += f_size.unsignedIntegerValue;
    }
    else if (error)
    {
      NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld",
            error.domain, (long)error.code);
    }
  }
  return res;
}

- (uint64_t)free_space
{
  uint64_t res = 0;
  __autoreleasing NSError* error = nil;
  NSDictionary* dict =
    [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
  if (dict && !error)
  {
    NSNumber* free_space_in_bytes = dict[NSFileSystemFreeSize];
    res = free_space_in_bytes.unsignedLongLongValue;
  }
  else if (error)
  {
    NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld",
          error.domain, (long)error.code);
  }
  return res;
}

@end
