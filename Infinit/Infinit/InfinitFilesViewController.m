//
//  InfinitFilesViewController.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesViewController.h"

#import "InfinitColor.h"
#import "InfinitFilesTableCell.h"

#import <Gap/InfinitDirectoryManager.h>

@interface InfinitFilesViewController () <UISearchBarDelegate,
                                          UITableViewDataSource,
                                          UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;
@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;
@property (nonatomic, readonly) NSArray* files;

@end

@implementation InfinitFilesViewController
{
@private
  NSString* _file_cell_id;
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _file_cell_id = @"file_table_cell";
  }
  return self;
}

- (void)viewDidLoad
{
  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitFilesTableCell.class) bundle:nil];
  [self.table_view registerNib:cell_nib forCellReuseIdentifier:_file_cell_id];
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
}

- (void)viewWillAppear:(BOOL)animated
{
  NSError* error = nil;
  NSString* dir = [InfinitDirectoryManager sharedInstance].download_directory;
  _files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&error];
  if (error)
  {
    NSLog(@"unable to access downloads directory");
  }
  [super viewWillAppear:animated];
}

#pragma mark - Search Bar Delegate

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.files.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell* cell = [tableView dequeueReusableCellWithIdentifier:_file_cell_id
                                                                forIndexPath:indexPath];
  return cell;
}

#pragma mark - Table View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
  [self.search_bar resignFirstResponder];
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Helpers

- (NSString*)pathForItem:(NSString*)item
{
  NSString* download_dir = [InfinitDirectoryManager sharedInstance].download_directory;
  return [download_dir stringByAppendingPathComponent:item];
}

@end
