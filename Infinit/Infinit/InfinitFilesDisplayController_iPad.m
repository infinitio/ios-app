//
//  InfinitFilesDisplayController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesDisplayController_iPad.h"

@interface InfinitFilesDisplayController_iPad ()

@end

@implementation InfinitFilesDisplayController_iPad

- (void)setEditing:(BOOL)editing
{
  _editing = editing;
}

- (void)setFilter:(InfinitFileTypes)filter
{
  _filter = filter;
}

- (void)setSearch_string:(NSString*)search_string
{
  _search_string = search_string;
}

- (void)filesDeleted
{}

- (void)folderAdded:(InfinitFolderModel*)folder
{
  NSMutableArray* temp = [self.all_folders mutableCopy];
  [temp insertObject:folder atIndex:0];
  self.all_folders = [temp copy];
}

- (void)folderRemoved:(InfinitFolderModel*)folder
{
  NSMutableArray* temp = [self.all_folders mutableCopy];
  [temp removeObject:folder];
  self.all_folders = [temp copy];
}

@end
