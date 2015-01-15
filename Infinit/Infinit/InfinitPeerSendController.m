//
//  InfinitPeerSendController.m
//  Infinit
//
//  Created by Christopher Crone on 13/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitPeerSendController.h"

#import "InfinitPeerSendFileCell.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitTemporaryFileManager.h>
#import <Gap/InfinitUserManager.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "NSString+email.h"

@interface InfinitPeerSendController () <UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton* clear;
@property (nonatomic) UIImagePickerController* image_picker_controller;
@property (nonatomic, weak) IBOutlet UITextField* recipient;
@property (nonatomic, weak) IBOutlet UIButton* send;
@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end

@implementation InfinitPeerSendController
{
@private
  NSString* _managed_files_id;

  NSMutableArray* _asset_urls;
}

- (void)viewDidLoad
{
  _asset_urls = [NSMutableArray array];
  [super viewDidLoad];
  self.recipient.delegate = self;
  _managed_files_id = [[InfinitTemporaryFileManager sharedInstance] createManagedFiles];
  UIGestureRecognizer* tapper =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  tapper.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tapper];
}

- (void)handleSingleTap:(UITapGestureRecognizer*)sender
{
  [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Text Field

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [[InfinitUserManager sharedInstance] searchUsers:textField.text
                                   performSelector:@selector(searchResults:)
                                          onObject:self];
  return YES;
}

- (void)searchResults:(NSArray*)results
{

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
  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];
  return files.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* identifier = @"peer_send_cell";
  InfinitPeerSendFileCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];
  cell.file_path.text = [files[indexPath.row] lastPathComponent];
  [cell setNeedsDisplay];
  return cell;
}

#pragma mark - User Interaction

- (void)clearInterface
{
  self.recipient.text = @"";
  _managed_files_id = [[InfinitTemporaryFileManager sharedInstance] createManagedFiles];
  [self.table_view reloadData];
  self.send.enabled = YES;
}

- (IBAction)addFilesTapped:(UIButton*)sender
{
  [self showImagePicker];
}

- (IBAction)clearTapped:(UIButton*)sender
{
  NSLog(@"xxx cleared");
  [[InfinitTemporaryFileManager sharedInstance] removeAssetLibraryURLList:_asset_urls
                                                         fromManagedFiles:_managed_files_id];
  [_asset_urls removeAllObjects];
  [self.table_view reloadData];
}

- (IBAction)sendTapped:(UIButton*)sender
{
  self.send.enabled = NO;
  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];
  if (files.count == 0)
    return;
  if (self.recipient.text.isEmail)
  {
    NSArray* ids = [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                                toRecipients:@[self.recipient.text]
                                                                 withMessage:@"from iOS"];
    [[InfinitTemporaryFileManager sharedInstance] setTransactionIds:ids
                                                    forManagedFiles:_managed_files_id];
    [self clearInterface];
  }
  else
  {
    [[InfinitUserManager sharedInstance] userWithHandle:self.recipient.text
                                        performSelector:@selector(userWithHandleCallback:)
                                               onObject:self];
  }
}

- (void)userWithHandleCallback:(InfinitUser*)user
{
  if (user == nil)
    return;

  NSArray* files =
    [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];

  NSArray* ids = [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                              toRecipients:@[user]
                                                               withMessage:@"from iOS"];
  [[InfinitTemporaryFileManager sharedInstance] setTransactionIds:ids
                                                  forManagedFiles:_managed_files_id];
  [self clearInterface];
}

#pragma mark - Image Picker

- (void)showImagePicker
{
  UIImagePickerController* image_picker_controller = [[UIImagePickerController alloc] init];
  image_picker_controller.modalPresentationStyle = UIModalPresentationCurrentContext;
  image_picker_controller.modalPresentationCapturesStatusBarAppearance = YES;
  image_picker_controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  image_picker_controller.mediaTypes = @[(id)kUTTypeImage,
                                         (id)kUTTypeMovie];
  image_picker_controller.delegate = self;
  self.image_picker_controller = image_picker_controller;
  [self presentViewController:self.image_picker_controller animated:YES completion:nil];
}

- (void)doneCopyingFiles
{
  NSLog(@"xxx done copying files: %@", [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id]);
  [self.table_view reloadData];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  NSLog(@"xxx info: %@", info);
  [self dismissViewControllerAnimated:YES completion:nil];
  [_asset_urls addObject:info[UIImagePickerControllerReferenceURL]];
  [[InfinitTemporaryFileManager sharedInstance] addAssetsLibraryURLList:@[info[UIImagePickerControllerReferenceURL]]
                                                        toManagedFiles:_managed_files_id
                                                        performSelector:@selector(doneCopyingFiles)
                                                               onObject:self];
}



@end
