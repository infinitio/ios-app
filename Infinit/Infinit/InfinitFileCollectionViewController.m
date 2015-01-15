//
//  InfinitFileCollectionViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/22/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFileCollectionViewController.h"

#import "FileGridCell.h"
#import "FileListCell.h"

@interface InfinitFileCollectionViewController ()

@property BOOL list_showing;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* style_bar_button;

//Sort Properties
@property BOOL sort_showing;
@property (strong, nonatomic) UIView* sort_view;
@property (strong, nonatomic) UISegmentedControl* sort_control;
@property (strong, nonatomic) UISwitch* links_only_switch;

@end

@implementation InfinitFileCollectionViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.list_showing = YES;
  self.sort_showing = NO;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return 27;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if(self.list_showing)
  {
    FileListCell* cell =
      (FileListCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"listCell" forIndexPath:indexPath];
    cell.name_label.text = @"Sample_1.jpg";
    cell.from_label.text = @"FROM GAETAN";
    
    return cell;
  }
  else
  {
    FileGridCell* cell =
      (FileGridCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"gridCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    return cell;
  }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if(self.list_showing)
  {
    return CGSizeMake(self.view.frame.size.width, 80);
  }
  else
  {
    return CGSizeMake(self.view.frame.size.width/3 - 2, self.view.frame.size.width/3 - 2);
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  if(self.list_showing)
  {
    return 0.0;
  }
  else
  {
    return 2.0;
  }
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  if(self.list_showing)
  {
    return 0.0;
  }
  else
  {
    return 2.0;
  }
}

- (IBAction)switchStyleButtonSelected:(id)sender
{
  if(self.list_showing)
  {
    self.list_showing = NO;
    [self.style_bar_button setImage:[UIImage imageNamed:@"icon-list"]];
    [self.collectionView reloadData];
  }
  else
  {
    self.list_showing = YES;
    [self.style_bar_button setImage:[UIImage imageNamed:@"icon-grid"]];
    [self.collectionView reloadData];
  }
}
- (IBAction)sortButtonSelected:(id)sender
{
  
  if(self.sort_showing == NO)
  {
    self.sort_showing = YES;
    if(!self.sort_view)
    {
      //Add a view with a segmented Control and a switch.
      self.sort_view =
        [[UIView alloc] initWithFrame:CGRectMake(0, -108, self.view.frame.size.width, 108)];
      self.sort_view.backgroundColor = [UIColor whiteColor];
      
      NSArray* items_array =
        [NSArray arrayWithObjects:@"Date", @"Name", @"Sender", @"Size", nil];
      self.sort_control = [[UISegmentedControl alloc] initWithItems:items_array];
      self.sort_control.frame = CGRectMake(10, 16, self.view.frame.size.width - 20, 32);
      self.sort_control.selectedSegmentIndex = 0;
      self.sort_control.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];
      [self.sort_view addSubview:self.sort_control];
      
      UILabel* links_only_label =
        [[UILabel alloc] initWithFrame:CGRectMake(10, 55, 200, 20)];
      links_only_label.text = @"Show my links only";
      links_only_label.textAlignment = NSTextAlignmentLeft;
      [self.sort_view addSubview:links_only_label];
      
      self.links_only_switch = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 50, 40, 20)];
//      _links_only_switch.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];
      [self.sort_view addSubview:self.links_only_switch];
      
      [self.view addSubview:self.sort_view];
    }
    
    [UIView animateWithDuration:.5 animations:^
    {
      self.sort_view.frame = CGRectMake(0, 0, self.view.frame.size.width, 108);
      self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,
                                             self.collectionView.frame.origin.y + 108,
                                             self.collectionView.frame.size.width,
                                             self.collectionView.frame.size.height);
    }
    completion:^(BOOL finished)
    {
      self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,
                                             self.collectionView.frame.origin.y,
                                             self.collectionView.frame.size.width,
                                            self.collectionView.frame.size.height - 108);
    }];
  }
  else
  {
    self.sort_showing = NO;
    [UIView animateWithDuration:.5 animations:^
    {
      self.sort_view.frame = CGRectMake(0, -108, self.view.frame.size.width, 108);
      self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,
                                             self.collectionView.frame.origin.y - 108,
                                             self.collectionView.frame.size.width,
                                             self.collectionView.frame.size.height + 108);
    }];
  }
}

@end
