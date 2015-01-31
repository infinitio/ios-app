//
//  InfinitFilesMultipleViewController.m
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesMultipleViewController.h"

#import "InfinitFilesTableCell.h"
#import "InfinitFilePreviewController.h"

@interface InfinitFilesMultipleViewController () <UIGestureRecognizerDelegate,
                                                  UITableViewDataSource,
                                                  UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end

@implementation InfinitFilesMultipleViewController
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
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;
  self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
  self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"%lu FILES", nil),
                               self.folder.files.count];
  [self.table_view reloadData];
  [super viewWillAppear:animated];
  [self.table_view deselectRowAtIndexPath:self.table_view.indexPathForSelectedRow animated:animated];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.folder.files.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilesTableCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_file_cell_id
                                                                      forIndexPath:indexPath];
  [cell configureCellWithFile:self.folder.files[indexPath.row]];
  return cell;
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView*)tableView
canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
  return YES;
}

- (void)tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    [self.folder deleteFileAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return 60.0f;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitFilePreviewController* preview_controller =
    [InfinitFilePreviewController controllerWithFolder:self.folder andIndex:indexPath.row];
  UINavigationController* nav_controller =
    [[UINavigationController alloc] initWithRootViewController:preview_controller];
  [self presentViewController:nav_controller animated:YES completion:nil];
}

#pragma mark - Button Handling

- (IBAction)backButtonTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
  return [gestureRecognizer isKindOfClass:UIScreenEdgePanGestureRecognizer.class];
}

@end
