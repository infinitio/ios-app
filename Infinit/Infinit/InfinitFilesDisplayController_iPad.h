//
//  InfinitFilesDisplayController_iPad.h
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFileModel.h"
#import "InfinitFolderModel.h"

@protocol InfinitFilesDisplayProtocol;

@interface InfinitFilesDisplayController_iPad : UIViewController

@property (nonatomic, readwrite) id<InfinitFilesDisplayProtocol> delegate;

@property (nonatomic, readwrite) NSArray* all_folders;
@property (nonatomic, readwrite) BOOL editing;
@property (nonatomic, readwrite) BOOL searching;

- (void)folderAdded:(InfinitFolderModel*)folder;
- (void)folderRemoved:(InfinitFolderModel*)folder;

@end

@protocol InfinitFilesDisplayProtocol <NSObject>

- (void)actionForFile:(InfinitFileModel*)file
               sender:(InfinitFilesDisplayController_iPad*)sender;
- (void)actionForFolder:(InfinitFolderModel*)folder
                 sender:(InfinitFilesDisplayController_iPad*)sender;

- (void)deleteFile:(InfinitFileModel*)file
              sender:(InfinitFilesDisplayController_iPad*)sender;
- (void)deleteFolder:(InfinitFolderModel*)folder
              sender:(InfinitFilesDisplayController_iPad*)sender;

@end;
