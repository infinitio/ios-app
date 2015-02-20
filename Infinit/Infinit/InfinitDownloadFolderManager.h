//
//  InfinitDownloadFolderManager.h
//  Infinit
//
//  Created by Christopher Crone on 28/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitFolderModel.h"

@protocol InfinitDownloadFolderManagerProtocol;

@interface InfinitDownloadFolderManager : NSObject

@property (nonatomic, weak, readwrite) id<InfinitDownloadFolderManagerProtocol> delegate;
@property (nonatomic, readonly) NSArray* completed_folders;

+ (instancetype)sharedInstance;

- (InfinitFolderModel*)completedFolderForTransactionMetaId:(NSString*)meta_id;

- (void)deleteFolder:(InfinitFolderModel*)folder;

@end

@protocol InfinitDownloadFolderManagerProtocol <NSObject>

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
                  addedFolder:(InfinitFolderModel*)folder;

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
               folderFinished:(InfinitFolderModel*)folder;

- (void)downloadFolderManager:(InfinitDownloadFolderManager*)sender
                deletedFolder:(InfinitFolderModel*)folder;

@end
