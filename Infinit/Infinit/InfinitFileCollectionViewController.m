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

@property BOOL listShowing;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* styleBarButton;


//Sort Properties
@property BOOL sortShowing;
@property (strong, nonatomic) UIView* sortView;
@property (strong, nonatomic) UISegmentedControl* sortControl;
@property (strong, nonatomic) UISwitch* linksOnlySwitch;


@end

@implementation InfinitFileCollectionViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  _listShowing = YES;
  _sortShowing = NO;

  
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return 27;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if(_listShowing)
  {
    FileListCell* cell = (FileListCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"listCell" forIndexPath:indexPath];
    return cell;

  }
  else
  {
    FileGridCell* cell = (FileGridCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"gridCell" forIndexPath:indexPath];
    return cell;
  }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if(_listShowing)
  {
    return CGSizeMake(320, 80);
  } else {
    return CGSizeMake(104, 104);
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
  if(_listShowing)
  {
    return 0.0;
  } else {
    return 2.0;
  }
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  if(_listShowing)
  {
    return 0.0;
  } else {
    return 2.0;
  }
}

#pragma mark <UICollectionViewDelegate>

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
- (IBAction)switchStyleButtonSelected:(id)sender
{
  if(_listShowing)
  {
    _listShowing = NO;
    [_styleBarButton setImage:[UIImage imageNamed:@"icon-list"]];
    [self.collectionView reloadData];
  } else {
    _listShowing = YES;
    [_styleBarButton setImage:[UIImage imageNamed:@"icon-grid"]];
    [self.collectionView reloadData];
  }
}
- (IBAction)sortButtonSelected:(id)sender
{
  
  if(_sortShowing == NO)
  {
    _sortShowing = YES;
    if(!_sortView)
    {
      //Add a view with a segmented Control and a switch.
      _sortView = [[UIView alloc] initWithFrame:CGRectMake(0, -108, 320, 108)];
      _sortView.backgroundColor = [UIColor whiteColor];
      
      NSArray *itemsArray = [NSArray arrayWithObjects:@"Date", @"Name", @"Sender", @"Size", nil];
      _sortControl = [[UISegmentedControl alloc] initWithItems:itemsArray];
      _sortControl.frame = CGRectMake(10, 16, 300, 32);
      _sortControl.selectedSegmentIndex = 0;
      _sortControl.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];
      [_sortView addSubview:_sortControl];
      
      UILabel *linksOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 55, 200, 20)];
      linksOnlyLabel.text = @"Show my links only";
      linksOnlyLabel.textAlignment = NSTextAlignmentLeft;
      [_sortView addSubview:linksOnlyLabel];
      
      _linksOnlySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(260, 50, 40, 20)];
//      _linksOnlySwitch.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];
      [_sortView addSubview:_linksOnlySwitch];
      
      [self.view addSubview:_sortView];
    }
    
    [UIView animateWithDuration:.5 animations:^{
      _sortView.frame = CGRectMake(0, 0, 320, 108);
      self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,self.collectionView.frame.origin.y + 108, self.collectionView.frame.size.width, self.collectionView.frame.size.height);
    } completion:^(BOOL finished){
      self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,self.collectionView.frame.origin.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height - 108);
    }];
  } else {
    _sortShowing = NO;
    [UIView animateWithDuration:.5 animations:^{
      _sortView.frame = CGRectMake(0, -108, 320, 108);
      self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,self.collectionView.frame.origin.y - 108, self.collectionView.frame.size.width, self.collectionView.frame.size.height + 108);
    }];

  }

  
  
  
}

@end
