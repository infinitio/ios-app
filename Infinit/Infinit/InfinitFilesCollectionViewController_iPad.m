//
//  InfinitFilesCollectionViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesCollectionViewController_iPad.h"

#import "InfinitFilesCollectionCell_iPad.h"
#import "InfinitFolderModel.h"
#import "InfinitFileModel.h"

@interface InfinitFilesCollectionViewController_iPad () <UICollectionViewDataSource,
                                                         UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView* collection_view;

@property (nonatomic, readonly) NSMutableArray* file_results;

@end

@implementation InfinitFilesCollectionViewController_iPad
{
@private
  NSString* _cell_id;
}

- (void)viewDidLoad
{
  _cell_id = @"files_collection_cell_ipad";
  [super viewDidLoad];
  self.collection_view.alwaysBounceVertical = YES;
  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesCollectionCell_iPad.class)
                                   bundle:nil];
  [self.collection_view registerNib:cell_nib forCellWithReuseIdentifier:_cell_id];
  _file_results = [[self filesFromFolders:self.all_folders] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  _file_results = [self searchAndFilterResults];
  [self.collection_view reloadData];
  for (NSIndexPath* index in self.collection_view.indexPathsForSelectedItems)
    [self.collection_view deselectItemAtIndexPath:index animated:NO];
}

#pragma mark - Editing

- (NSArray*)current_selection
{
  if (!self.editing)
    return nil;
  NSMutableArray* res = [NSMutableArray array];
  for (NSIndexPath* index in self.collection_view.indexPathsForSelectedItems)
    [res addObject:self.file_results[index.row]];
  return res;
}

- (void)setEditing:(BOOL)editing
{
  if (self.editing == editing)
    return;
  [super setEditing:editing];
  self.collection_view.allowsMultipleSelection = editing;
  for (NSIndexPath* index in self.collection_view.indexPathsForSelectedItems)
    [self.collection_view deselectItemAtIndexPath:index animated:NO];
}

- (void)filesDeleted
{
  [self.collection_view performBatchUpdates:^
  {
    NSMutableArray* temp = [self.file_results mutableCopy];
    [temp removeObjectsInArray:[self searchAndFilterResults]];
    NSMutableArray* indexes = [NSMutableArray array];
    for (InfinitFileModel* file in temp)
    {
      NSUInteger index = [self.file_results indexOfObject:file];
      if (index != NSNotFound)
      {
        [indexes addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        [self.file_results removeObject:file];
      }
    }
    if (indexes.count > 0)
      [self.collection_view deleteItemsAtIndexPaths:indexes];
    self.editing = NO;
  } completion:NULL];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
  return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.file_results.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                  cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesCollectionCell_iPad* cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:_cell_id
                                              forIndexPath:indexPath];
  [cell configureForFile:self.file_results[indexPath.row]];
  cell.selected = [collectionView.indexPathsForSelectedItems containsObject:indexPath];
  return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView*)collectionView
didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.editing)
  {

  }
  else
  {
    [self.delegate actionForFile:self.file_results[indexPath.row] sender:self];
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
  }
}

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
 }

 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
 }

 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {

 }
 */

#pragma mark - Files Display

- (void)folderAdded:(InfinitFolderModel*)folder
{
  @synchronized(self.all_folders)
  {
    if ([self.all_folders containsObject:folder])
      return;
    [super folderAdded:folder];
    if (!self.search_string.length)
    {
      [self.collection_view performBatchUpdates:^
      {
        NSArray* new_files = [self filesFromFolders:@[folder]];
        NSMutableArray* indexes = [NSMutableArray array];
        for (NSInteger i = 0; i < new_files.count; i++)
        {
          [self.file_results insertObject:new_files[i] atIndex:i];
          [indexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [self.collection_view insertItemsAtIndexPaths:indexes];
      } completion:NULL];
    }
  }
}

- (void)folderRemoved:(InfinitFolderModel*)folder
{
  @synchronized(self.all_folders)
  {
    if (![self.all_folders containsObject:folder])
      return;
    [super folderRemoved:folder];
    [self.collection_view performBatchUpdates:^
    {
      NSArray* deleted_files = [self filesFromFolders:@[folder]];
      NSMutableArray* indexes = [NSMutableArray array];
      for (InfinitFileModel* file in deleted_files)
      {
        NSUInteger index = [self.file_results indexOfObject:file];
        [indexes addObject:[NSIndexPath indexPathForRow:index inSection:0]];
      }
      [self.collection_view deleteItemsAtIndexPaths:indexes];
    } completion:NULL];
  }
}

#pragma mark - Helpers

- (NSArray*)filesFromFolders:(NSArray*)folders
{
  NSMutableArray* res = [NSMutableArray array];
  for (InfinitFolderModel* folder in folders)
  {
    for (InfinitFileModel* file in folder.files)
      [res addObject:file];
  }
  return res;
}

#pragma mark - Search

- (void)setFilter:(InfinitFileTypes)filter
{
  if (self.filter == filter)
    return;
  @synchronized(self)
  {
    [super setFilter:filter];
    _file_results = [self searchAndFilterResults];
    [self.collection_view reloadData];
  }
}

- (void)setSearch_string:(NSString*)search_string
{
  if ([self.search_string isEqualToString:search_string])
    return;
  [super setSearch_string:search_string];
  if (self.search_string.length)
    _file_results = [self searchAndFilterResults];
  else
    _file_results = [[self filesFromFolders:self.all_folders] mutableCopy];
  [self.collection_view reloadData];
}

- (NSMutableArray*)searchAndFilterResults
{
  NSMutableArray* res = [NSMutableArray array];
  for (InfinitFolderModel* folder in self.all_folders)
  {
    for (InfinitFileModel* file in folder.files)
      if ([file matchesType:self.filter] && [file containsString:self.search_string])
        [res addObject:file];
  }
  return res;
}

@end
