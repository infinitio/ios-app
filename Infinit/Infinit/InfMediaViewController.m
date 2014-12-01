//
//  InfMediaViewController.m
//  Infinit
//
//  Created by Michael Dee on 6/29/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfMediaViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "InfCollectionViewCell.h"
#import "SendViewController.h"
#import <Gap/InfinitTemporaryFileManager.h>
#import "FileInformation.h"


@interface InfMediaViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate>

@property(nonatomic, strong) NSArray* assets;
@property(nonatomic, strong) UICollectionView* mediaCollectionView;
@property (nonatomic, strong) NSMutableDictionary* selectedMedia;
@property (nonatomic, strong) UIButton* nextButton;
@property(nonatomic, strong) NSMutableArray* filesToSend;

@end

@implementation InfMediaViewController
{
@private
    NSString* _managed_files_id;
}
@synthesize assets, mediaCollectionView, selectedMedia, nextButton;



- (id)initWithNibName:(NSString*)nibNameOrNil
               bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1];
    
}
    


- (void)viewDidLoad
{
    [super viewDidLoad];

    _managed_files_id = [[InfinitTemporaryFileManager sharedInstance] createManagedFiles];
    
    //Collection View Creation
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    mediaCollectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                             collectionViewLayout:layout];
    [mediaCollectionView setDataSource:self];
    [mediaCollectionView setDelegate:self];
    [mediaCollectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:@"cellIdentifier"];
    [mediaCollectionView setBackgroundColor:[UIColor blackColor]];
    [mediaCollectionView registerClass:[InfCollectionViewCell class]
            forCellWithReuseIdentifier:@"mediaCell"];
    [self.view addSubview:mediaCollectionView];
     
    //The height of the screen - the button size - the navbar size - the status bar size.
    nextButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 49 - 50, 320, 50)];
    nextButton.backgroundColor = [UIColor colorWithRed:242/255.0 green:94/255.0 blue:90/255.0 alpha:1];
    [nextButton setTitle:@"Next (0 Selected)" forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextButtonSelected) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];
    
    //Back Could Say Cancel if the view is pushed onto stack.
    /*
     UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
     initWithTitle: @"Cancel"
     style: UIBarButtonItemStyleBordered
     target:self action: @selector(popBack)];
     [self.navigationItem setLeftBarButtonItem:backButton];
     */
    
    
    [self loadAssets];
    
}

- (void)loadAssets
{
    assets = [@[] mutableCopy];
    __block NSMutableArray* tmpAssets = [@[] mutableCopy];
    ALAssetsLibrary* assetsLibrary = [self defaultAssetsLibrary];
    
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup* group, BOOL* stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result)
            {
                [tmpAssets addObject:result];
            }
        }];
        
        // Can sort these things.  DO THIS. *****
        //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        //self.assets = [tmpAssets sortedArrayUsingDescriptors:@[sort]];
        self.assets = tmpAssets;
        
        [self.mediaCollectionView reloadData];
    } failureBlock:^(NSError* error) {
        NSLog(@"Error loading images %@", error);
    }];
}

- (void)nextButtonSelected
{
    NSArray* managedFiles = [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];
    //Create Files for each one if it isn't managed already.
    NSMutableArray* filesToSend = [[NSMutableArray alloc] init];
    
    for(NSIndexPath* indexPath in selectedMedia)
    {
        FileInformation* fileInfoObject = [selectedMedia objectForKey:indexPath];
        [filesToSend addObject:fileInfoObject.fileName];
        
        if(![managedFiles containsObject:fileInfoObject.fileName])
        {
            ALAsset* asset = self.assets[self.assets.count - 1 - fileInfoObject.indexPath.row];
            ALAssetRepresentation* rep = [asset defaultRepresentation];
            Byte* buffer = (Byte*)malloc(rep.size);
            NSUInteger buffered = [rep getBytes:buffer
                                     fromOffset:0.0
                                         length:rep.size
                                          error:nil];
            NSData* fileData = [NSData dataWithBytesNoCopy:buffer
                                                    length:buffered
                                              freeWhenDone:YES];
            
            [[InfinitTemporaryFileManager sharedInstance] addData:fileData
                                                     withFilename:fileInfoObject.fileName
                                                   toManagedFiles:_managed_files_id];
        }
    }
    
    //Update array.
    managedFiles = [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:_managed_files_id];

    //Removal here.
    for(NSString* managedFile in managedFiles)
    {
        if(![filesToSend containsObject:managedFile])
        {
            [[InfinitTemporaryFileManager sharedInstance] removeFiles:@[managedFile]
                                                     fromManagedFiles:_managed_files_id];
        }
    }
    
    NSInteger count = managedFiles.count;
    NSLog([NSString stringWithFormat:@"%ld is the count of files", (long)count]);
    
    //Present the send view controller.
    SendViewController *viewController = [[SendViewController alloc] init];
    //viewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:viewController animated:YES];
    
}

- (void)popBack
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark AssetsLirbary Call

- (ALAssetsLibrary*)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary* library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return assets.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    InfCollectionViewCell* cell= (InfCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"mediaCell"
                                                                                                   forIndexPath:indexPath];
    
    ALAsset* asset = self.assets[self.assets.count - 1 - indexPath.row];
    UIImage* image = [[UIImage alloc] init];
    CGFloat scale  = 1;
    
    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
    {
        
        if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty) {
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"mm:ss"];

            cell.durationLabel.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]]];
            [cell.contentView addSubview:cell.durationLabel];

        }
        
        
        UIImage* thumbnail = [UIImage imageWithCGImage:[asset thumbnail]
                                                 scale:scale
                                           orientation:UIImageOrientationUp];
        
        image = thumbnail;
        
    }

    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)
    {
        image = [UIImage imageWithCGImage:[asset thumbnail]
                                    scale:scale
                              orientation:UIImageOrientationUp];
    }
    
    cell.imageView.image = image;
    cell.backgroundColor=[UIColor greenColor];
    
    if([selectedMedia objectForKey:indexPath])
    {
        cell.checkMark.hidden = NO;
    } else {
        cell.checkMark.hidden = YES;
    }
    
    /* Animation stuff.
    if(indexPath.row <12) {
        
        
        CGRect finalCellFrame = cell.frame;
        cell.frame = CGRectMake(finalCellFrame.origin.x, finalCellFrame.origin.y + 500.0f, finalCellFrame.size.width, finalCellFrame.size.height);
        
        
        CGFloat gravityDirectionY = -1;
        CGFloat boundaryPointY = finalCellFrame.origin.y;
        
        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[cell.contentView]];
        gravityBehavior.gravityDirection = CGVectorMake(0.0, gravityDirectionY);
        [cell.animator addBehavior:gravityBehavior];
        
        
        UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[cell.contentView]];
        [collisionBehavior addBoundaryWithIdentifier:@"cellBoundary"
                                           fromPoint:CGPointMake(finalCellFrame.origin.x, boundaryPointY)
                                             toPoint:CGPointMake(finalCellFrame.origin.x + finalCellFrame.size.width, boundaryPointY)];
        [cell.animator addBehavior:collisionBehavior];
        
        
//        UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[cell.contentView]
//                                                                        mode:UIPushBehaviorModeInstantaneous];
//        pushBehavior.magnitude = pushMagnitude;
//        [cell.animator addBehavior:pushBehavior];
        
        
        UIDynamicItemBehavior *menuViewBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[cell.contentView]];
        menuViewBehavior.elasticity = 0.4;
        [cell.animator addBehavior:menuViewBehavior];
        
//        CGRect finalCellFrame = cell.frame;
//        cell.frame = CGRectMake(finalCellFrame.origin.x, finalCellFrame.origin.y + 500.0f, finalCellFrame.size.width, finalCellFrame.size.height);
//        
//        [UIView animateWithDuration:0.3f animations:^(void){
//            cell.frame = finalCellFrame;
//        }];
    }
    */

    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
    return CGSizeMake(104, 104);
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
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0;
}

# pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
    //Redraw The Image as blurry, and put a check mark on it.
    InfCollectionViewCell* cell = (InfCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];

    
    if(selectedMedia == nil)
    {
        selectedMedia = [[NSMutableDictionary alloc] init];
    }
    
    if(_filesToSend == nil)
    {
        _filesToSend = [[NSMutableArray alloc] init];
    }
    
    ALAsset* asset = self.assets[self.assets.count - 1 - indexPath.row];
    ALAssetRepresentation* rep = [asset defaultRepresentation];
    NSString* fileName = [rep filename];
    
    if([selectedMedia objectForKey:indexPath])
    {
        cell.checkMark.hidden = YES;
        
        [selectedMedia removeObjectForKey:indexPath];
        
        NSString *buttonString = [NSString stringWithFormat:@"Next (%lu Selected)", (unsigned long)selectedMedia.allKeys.count];
        [nextButton setTitle:buttonString
                    forState:UIControlStateNormal];
    }
    else
    {
        cell.checkMark.hidden = NO;

        FileInformation* fileInfoObject = [[FileInformation alloc] init];
        fileInfoObject.fileName = fileName;
        fileInfoObject.indexPath = indexPath;
        [selectedMedia setObject:fileInfoObject forKey:indexPath];
        
        NSString* buttonString = [NSString stringWithFormat:@"Next (%lu Selected)", (unsigned long)selectedMedia.allKeys.count];
        [nextButton setTitle:buttonString
                    forState:UIControlStateNormal];
    }
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

@end
