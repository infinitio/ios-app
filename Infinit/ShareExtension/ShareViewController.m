//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Christopher Crone on 07/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "ShareViewController.h"

#import "InfinitColor.h"
#import "InfinitExtensionInfo.h"
#import "InfinitProgressView.h"
#import "InfinitWormhole.h"

@import MobileCoreServices;

@interface ShareViewController ()

@property (nonatomic, weak) IBOutlet UIView* background_view;
@property (nonatomic, weak) IBOutlet UIButton* cancel_button;
@property (nonatomic, weak) IBOutlet UILabel* top_message_label;
@property (nonatomic, weak) IBOutlet UILabel* bottom_message_label;
@property (nonatomic, weak) IBOutlet UIImageView* bottom_icon;
@property (nonatomic, weak) IBOutlet UIView* message_view;
@property (nonatomic, weak) IBOutlet UIButton* ok_button;
@property (nonatomic, weak) IBOutlet InfinitProgressView* progress_view;

@property (atomic, readonly) NSMutableArray* item_paths;
@property (nonatomic, readonly) BOOL own_app;
@property (nonatomic, readonly) dispatch_semaphore_t fetched_items;

@property (nonatomic, readonly) uint64_t free_space;
@property (nonatomic, readonly) NSString* temp_dir;

@end

static NSUInteger _min_delay = 3;

@implementation ShareViewController

- (void)dealloc
{
  [[InfinitWormhole sharedInstance] unregisterForWormholeNotifications:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self addParallax];
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
  UIColor* enabled_color = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  UIColor* disabled_color = [InfinitColor colorWithGray:128];
  [self.ok_button setBackgroundImage:[self imageWithColor:enabled_color]
                            forState:UIControlStateNormal];
  [self.ok_button setBackgroundImage:[self imageWithColor:disabled_color]
                            forState:UIControlStateDisabled];

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
  _fetched_items = dispatch_semaphore_create(0);
  [self deleteFiles];
  _own_app = NO;
  [[InfinitWormhole sharedInstance] registerForWormholeNotification:INFINIT_PONG_NOTIFICATION
                                                           observer:self
                                                           selector:@selector(pongReceived)];
  [[InfinitWormhole sharedInstance] sendWormholeNotification:INFINIT_PING_NOTIFICATION];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    if (self.own_app)
    {
      self.top_message_label.text = NSLocalizedString(@"Preparing your files...", nil);
      self.bottom_message_label.text = NSLocalizedString(@"Files ready!", nil);
      [self.ok_button setTitle:NSLocalizedString(@"SEND", nil) forState:UIControlStateNormal];
    }
    else
    {
      self.top_message_label.text =
        NSLocalizedString(@"Your files are being\ncopied to Infinit...", nil);
      NSString* text = NSLocalizedString(@"Open Infinit now\nto send them!", nil);
      NSMutableAttributedString* str =
        [[NSMutableAttributedString alloc] initWithString:text
                                               attributes:[self textAttributesBold:NO]];
      NSRange bold_range = [str.string rangeOfString:NSLocalizedString(@"Infinit", nil)];
      if (bold_range.location != NSNotFound)
        [str setAttributes:[self textAttributesBold:YES] range:bold_range];
      self.bottom_message_label.attributedText = str;
      [self.ok_button setTitle:NSLocalizedString(@"GOT IT", nil) forState:UIControlStateNormal];
    }
    self.progress_view.alpha = 1.0f;
    self.top_message_label.alpha = 1.0f;
    self.bottom_message_label.alpha = 0.3f;
    self.bottom_icon.alpha = 0.3f;
  });
  [super viewWillAppear:animated];
  self.background_view.alpha = 0.0f;
  CGFloat screen_h = [UIScreen mainScreen].bounds.size.height;
  self.message_view.transform =
    CGAffineTransformMakeTranslation(0.0f, -(screen_h * 0.1f));
  self.message_view.alpha = 0.0f;
  self.cancel_button.alpha = 0.0f;
  self.cancel_button.enabled = YES;
  self.ok_button.enabled = NO;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    NSExtensionItem* item = self.extensionContext.inputItems.firstObject;
    if (self.item_paths == nil)
      _item_paths = [NSMutableArray array];
    for (NSItemProvider* provider in item.attachments)
    {
      dispatch_semaphore_t fetch_sema = dispatch_semaphore_create(0);
      if ([provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeFileURL])
      {
        [provider loadItemForTypeIdentifier:(NSString*)kUTTypeFileURL
                                    options:nil
                          completionHandler:^(NSURL* url, NSError* error)
         {
           if (!error)
           {
             [self.item_paths addObject:url.path];
           }
           dispatch_semaphore_signal(fetch_sema);
         }];
      }
      else if (([provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeImage] ||
               [provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeAudiovisualContent]) &&
               ![provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeURL])
      {
        [provider loadItemForTypeIdentifier:(NSString*)kUTTypeData
                                    options:nil
                          completionHandler:^(NSURL* url, NSError* error)
        {
          if (!error)
          {
            [self.item_paths addObject:url.path];
            dispatch_semaphore_signal(fetch_sema);
          }
          else if ([provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeImage])
          {
            [provider loadItemForTypeIdentifier:(NSString*)kUTTypeImage
                                        options:nil
                              completionHandler:^(UIImage* image, NSError* error)
            {
              if (image && !error)
              {
                NSDate* date = [NSDate date];
                NSDateFormatter* date_formatter = [[NSDateFormatter alloc] init];
                date_formatter.dateFormat = @"yyyy-MM-DD HH:mm:ss";
                NSString* filename =
                  [NSString stringWithFormat:@"Image-%@.jpg", [date_formatter stringFromDate:date]];
                NSData* data = UIImageJPEGRepresentation(image, 1.0f);
                NSString* path = [self.temp_dir stringByAppendingPathComponent:filename];
                [data writeToFile:path atomically:NO];
                [self.item_paths addObject:path];
              }
              dispatch_semaphore_signal(fetch_sema);
            }];
          }
        }];
      }
      else if ([provider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeURL])
      {
        [provider loadItemForTypeIdentifier:(NSString*)kUTTypeURL
                                    options:nil
                          completionHandler:^(NSURL* url, NSError* error)
         {
           if (!error)
           {
             NSURLRequest* request = [NSURLRequest requestWithURL:url];
             NSURLResponse* response = nil;
             NSError* request_error = nil;
             NSData* data = [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response
                                                              error:&error];
             if (!request_error && data.length)
             {
               NSString* filename = response.suggestedFilename;
               NSString* path = [self.temp_dir stringByAppendingPathComponent:filename];
               [data writeToFile:path atomically:NO];
               [self.item_paths addObject:path];
             }
           }
           dispatch_semaphore_signal(fetch_sema);
         }];
      }
      else
      {
        dispatch_semaphore_signal(fetch_sema);
      }
      dispatch_semaphore_wait(fetch_sema, DISPATCH_TIME_FOREVER);
    }
    dispatch_semaphore_signal(self.fetched_items);
  });
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.progress_view.animate_progress = YES;
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
     dispatch_semaphore_wait(self.fetched_items, DISPATCH_TIME_FOREVER);
     NSDate* start = [NSDate date];
     BOOL success = [self copyFiles];
     NSDate* finish = [NSDate date];
     NSInteger delay = _min_delay;
     if ([finish timeIntervalSinceDate:start] >= (NSTimeInterval)_min_delay)
       delay = 0;
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
     {
       NSString* top_text = [self.top_message_label.text copy];
       NSString* bottom_text = [self.bottom_message_label.text copy];
       NSString* button_text = [self.ok_button.titleLabel.text copy];
       NSRange top_bold_range = NSMakeRange(NSNotFound, 0);
       NSRange bottom_bold_range = NSMakeRange(NSNotFound, 0);
       UIImage* image = nil;
       if (success)
       {
         image = [UIImage imageNamed:@"icon-extension-check"];
         bottom_bold_range = [bottom_text rangeOfString:NSLocalizedString(@"Infinit", nil)];
       }
       else
       {
         image = [UIImage imageNamed:@"icon-extension-error"];
         top_text = NSLocalizedString(@"Oops!\nNot enough space.", nil);
         top_bold_range = [top_text rangeOfString:NSLocalizedString(@"Oops!", nil)];
         button_text = NSLocalizedString(@"GOT IT", nil);
       }
       NSMutableAttributedString* top_message =
        [[NSMutableAttributedString alloc] initWithString:top_text
                                               attributes:[self textAttributesBold:NO]];
       if (top_bold_range.location != NSNotFound)
         [top_message setAttributes:[self textAttributesBold:YES] range:top_bold_range];
       NSMutableAttributedString* bottom_message =
         [[NSMutableAttributedString alloc] initWithString:bottom_text
                                                attributes:[self textAttributesBold:NO]];
       if (bottom_bold_range.location != NSNotFound)
         [bottom_message setAttributes:[self textAttributesBold:YES] range:bottom_bold_range];
       dispatch_async(dispatch_get_main_queue(), ^
       {
         self.progress_view.image = image;
         [self.ok_button setTitle:button_text forState:UIControlStateNormal];
         self.ok_button.enabled = YES;
         self.top_message_label.attributedText = top_message;
         self.bottom_message_label.attributedText = bottom_message;
         if (success)
         {
           self.progress_view.alpha = 0.3f;
           [UIView animateWithDuration:0.5f animations:^
           {
             self.top_message_label.alpha = 0.3f;
             self.bottom_message_label.alpha = 1.0f;
             self.bottom_icon.alpha = 1.0f;
           }];
         }
       });
     });
   }];
}

#pragma mark - Pong Handling

- (void)pongReceived
{
  _own_app = YES;
}

#pragma mark - File Handling

- (void)deleteTemporaryFiles
{
  NSFileManager* manager = [NSFileManager defaultManager];
  NSArray* contents = [manager contentsOfDirectoryAtPath:self.temp_dir error:nil];
  for (NSString* file in contents)
  {
    NSString* path = [self.temp_dir stringByAppendingPathComponent:file];
    [manager removeItemAtPath:path error:nil];
  }
}

- (void)deleteFiles
{
  NSFileManager* manager = [NSFileManager defaultManager];
  NSString* files_path = [InfinitExtensionInfo sharedInstance].files_path;
  NSArray* contents = [manager contentsOfDirectoryAtPath:files_path error:nil];
  for (NSString* file in contents)
  {
    NSString* path = [files_path stringByAppendingPathComponent:file];
    [manager removeItemAtPath:path error:nil];
  }
  contents = [manager contentsOfDirectoryAtPath:self.temp_dir error:nil];
  for (NSString* file in contents)
  {
    NSString* path = [self.temp_dir stringByAppendingPathComponent:file];
    [manager removeItemAtPath:path error:nil];
  }
  [manager removeItemAtPath:[InfinitExtensionInfo sharedInstance].internal_files_path error:nil];
}

- (BOOL)copyFiles
{
  if (self.own_app)
  {
    return YES;
  }
  else
  {
    if ([self sizeOfFiles:self.item_paths] > self.free_space)
    {
      [self deleteTemporaryFiles];
      return NO;
    }

    for (NSString* path in self.item_paths)
    {
      NSError* error = nil;
      NSString* files_path = [InfinitExtensionInfo sharedInstance].files_path;
      NSString* destination_path =
        [files_path stringByAppendingPathComponent:path.lastPathComponent];
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
          destination_path = [files_path stringByAppendingPathComponent:new_filename];
      }
      [[NSFileManager defaultManager] copyItemAtPath:path toPath:destination_path error:&error];
      if (error)
      {
        NSLog(@"Unable to copy %@ to %@: %@", path, destination_path, error);
      }
    }
    [self deleteTemporaryFiles];
    return YES;
  }
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
       if (self.own_app)
       {
         InfinitWormhole* wormhole = [InfinitWormhole sharedInstance];
         [wormhole sendWormholeNotification:INFINIT_EXTENSION_FILES_NOTIFICATION];
       }
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
  NSString* internal_files_path = [InfinitExtensionInfo sharedInstance].internal_files_path;
  NSString* path = [internal_files_path stringByAppendingPathComponent:@"files"];
  [self.item_paths writeToFile:path atomically:YES];
  [self doneAnimationWithCopy:YES];
}

#pragma mark - Helpers

- (NSString*)temp_dir
{
  NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fetched_files"];
  NSFileManager* manager = [NSFileManager defaultManager];
  if (![manager fileExistsAtPath:path])
  {
    [manager createDirectoryAtPath:path
       withIntermediateDirectories:YES
                        attributes:@{NSURLIsExcludedFromBackupKey: @YES} 
                             error:nil];
  }
  return path;
}

- (void)addParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* vertical =
  [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  vertical.minimumRelativeValue = @(-10.0f);
  vertical.maximumRelativeValue = @(10.0f);

  // Set horizontal effect
  UIInterpolatingMotionEffect* horizontal =
  [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                  type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontal.minimumRelativeValue = @(-10.0f);
  horizontal.maximumRelativeValue = @(10.0f);

  // Create group to combine both
  UIMotionEffectGroup* group = [UIMotionEffectGroup new];
  group.motionEffects = @[horizontal, vertical];

  // Add both effects to your view
  [self.message_view addMotionEffect:group];
}

- (NSDictionary*)textAttributesBold:(BOOL)bold
{
  UIFont* font = nil;
  if (bold)
    font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
  else
    font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
  return @{NSFontAttributeName: font,
           NSParagraphStyleAttributeName: [NSParagraphStyle defaultParagraphStyle],
           NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73]};
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

- (UIImage*)imageWithColor:(UIColor*)color
{
  UIImage* res = nil;
  CGRect cancel_rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
  UIGraphicsBeginImageContext(cancel_rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, cancel_rect);
  res = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return res;
}

@end
