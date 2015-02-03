//
//  InfinitDownloadFolderManager.m
//  Infinit
//
//  Created by Christopher Crone on 28/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitDownloadFolderManager.h"

#import <Gap/InfinitDirectoryManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.DownloadFolderManager");

static InfinitDownloadFolderManager* _instance = nil;

@interface InfinitDownloadFolderManager ()

@property (nonatomic, readonly) NSString* download_dir;
@property (nonatomic, readonly) NSMutableDictionary* folder_map;

@end

@implementation InfinitDownloadFolderManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use the sharedInstance");
  if (self = [super init])
  {
    [self loadFolders];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadFolders
{
  if (_folder_map == nil)
    _folder_map = [NSMutableDictionary dictionary];
  NSError* error = nil;
  NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.download_dir
                                                                          error:&error];
  if (error)
  {
    ELLE_ERR("%s: unable to access downloads directory", self.description.UTF8String);
    return;
  }
  NSString* path;
  for (NSString* folder_name in contents)
  {
    path = [self.download_dir stringByAppendingPathComponent:folder_name];
    InfinitFolderModel* folder = [[InfinitFolderModel alloc] initWithPath:path];
    if (folder.files.count == 0 && folder.done)
      [folder deleteFolder];
    else
      [self.folder_map setObject:folder forKey:folder.id_];
  }
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitDownloadFolderManager alloc] init];
  return _instance;
}

#pragma mark - General

- (void)setDelegate:(id<InfinitDownloadFolderManagerProtocol>)delegate
{
  _delegate = delegate;
}

- (NSArray*)completed_folders
{
  NSArray* all_folders = self.folder_map.allValues;
  NSMutableArray* res = [NSMutableArray array];
  NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"ctime" ascending:NO];
  for (InfinitFolderModel* folder in all_folders)
  {
    if (folder.done)
      [res addObject:folder];
  }
  return [res sortedArrayUsingDescriptors:@[sort]];
}

- (void)deleteFolder:(InfinitFolderModel*)folder
{
  [self.folder_map removeObjectForKey:folder.id_];
  [_delegate downloadFolderManager:self deletedFolder:folder];
  [folder deleteFolder];
}

#pragma mark - Transaction Updates

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* txn_id = notification.userInfo[@"id"];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:txn_id];
  switch (transaction.status)
  {
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    {
      NSString* path = [self.download_dir stringByAppendingPathComponent:transaction.meta_id];
      if (![[NSFileManager defaultManager] fileExistsAtPath:path])
      {
        return;
      }
      if ([self.folder_map objectForKey:transaction.meta_id] == nil)
      {
        InfinitFolderModel* folder = [[InfinitFolderModel alloc] initWithPath:path];
        folder.done = NO;
        [self.folder_map setObject:folder forKey:folder.id_];
        [_delegate downloadFolderManager:self addedFolder:folder];
      }
      return;
    }

    case gap_transaction_finished:
    {
      InfinitFolderModel* folder = [self.folder_map objectForKey:transaction.meta_id];
      if (folder == nil)
        return;
      folder.done = YES;
      [_delegate downloadFolderManager:self folderFinished:folder];
      return;
    }

    case gap_transaction_canceled:
    case gap_transaction_failed:
    {
      InfinitFolderModel* folder = [self.folder_map objectForKey:transaction.meta_id];
      if (folder == nil)
        return;
      [self.folder_map removeObjectForKey:folder.id_];
      [_delegate downloadFolderManager:self deletedFolder:folder];
      [folder deleteFolder];
      return;
    }

    default:
      return;
  }
}

#pragma mark - Helpers

- (NSString*)download_dir
{
  return [InfinitDirectoryManager sharedInstance].download_directory;
}

@end
