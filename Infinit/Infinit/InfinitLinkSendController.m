//
//  InfinitLinkSendController.m
//  Infinit
//
//  Created by Christopher Crone on 14/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkSendController.h"
#import "InfinitPeerSendFileCell.h"

#import <Gap/InfinitLinkTransactionManager.h>

#import <Photos/Photos.h>

@interface InfinitLinkSendController ()

@end

@implementation InfinitLinkSendController
{
@private
  NSMutableArray* _files;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _files = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Table

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 30.0f;
}

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  @synchronized(_files)
  {
    return _files.count;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* identifier = @"peer_send_cell";
  InfinitPeerSendFileCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  cell.file_path.text = [_files[indexPath.row] lastPathComponent];
  [cell setNeedsDisplay];
  return cell;
}

#pragma mark - User Interaction

- (void)clearInterface
{
  [_files removeAllObjects];
  [self.table_view reloadData];
  self.send.enabled = YES;
}

- (IBAction)addFilesTapped:(UIButton*)sender
{
  [self showImagePicker];
}

- (IBAction)getLinkTapped:(UIButton*)sender
{
  self.send.enabled = NO;
  if (_files.count == 0)
    return;
  [[InfinitLinkTransactionManager sharedInstance] createLinkWithFiles:_files
                                                          withMessage:@"from iOS"];
  [self clearInterface];
}

#pragma mark - Image Picker

- (void)showImagePicker
{
  UIImagePickerController* image_picker_controller = [[UIImagePickerController alloc] init];
  image_picker_controller.modalPresentationStyle = UIModalPresentationCurrentContext;
  image_picker_controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  image_picker_controller.delegate = self;

  self.image_picker_controller = image_picker_controller;
  [self presentViewController:self.image_picker_controller animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  [self dismissViewControllerAnimated:YES completion:nil];
  PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[info[UIImagePickerControllerReferenceURL]]
                                                options:nil] firstObject];
  [asset requestContentEditingInputWithOptions:nil
                             completionHandler:^(PHContentEditingInput* contentEditingInput,
                                                 NSDictionary* info)
   {
     NSString* file_path = contentEditingInput.fullSizeImageURL.path;
     NSString* temp_dir = NSTemporaryDirectory();
     if (![[NSFileManager defaultManager] fileExistsAtPath:temp_dir isDirectory:nil])
     {
       [[NSFileManager defaultManager] createDirectoryAtPath:temp_dir
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
     }
     NSString* send_path = [temp_dir stringByAppendingPathComponent:file_path.lastPathComponent];
     [[NSFileManager defaultManager] copyItemAtPath:file_path toPath:send_path error:nil];
     [_files addObject:send_path];
     [self.table_view reloadData];
   }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
