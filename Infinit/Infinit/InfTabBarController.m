//
//  InfTabBarController.m
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfTabBarController.h"

@interface InfTabBarController () 

@property (nonatomic, strong) UIView *tealShadowLine;

@end

@implementation InfTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.delegate = self;
  
  self.tabBar.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];

  [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
  [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
  [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:8], NSFontAttributeName, nil] forState:UIControlStateNormal];
  
  UIView *shadowLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
  shadowLine.backgroundColor = [UIColor grayColor];
  shadowLine.alpha = .5;
  [self.tabBar addSubview:shadowLine];
  
  _tealShadowLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 1)];
  _tealShadowLine.backgroundColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];
  [self.tabBar addSubview:_tealShadowLine];
  
  // Add the sendImage over the bar button item.
  UIImageView *sendBgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send-bg"]];
  sendBgImage.center = CGPointMake(160, 22);
  [self.tabBar addSubview:sendBgImage];
  
  UIImageView *sendImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send"]];
  sendImage.center = CGPointMake(160, 27);
  [self.tabBar addSubview:sendImage];
  
  //Check for the badge items here.  Not yet
  _badgeLabel = [[TabBarBadgeLabel alloc] initWithFrame:CGRectMake(0, 0, 16, 16)
                                                 onItem:0
                                              withBadge:4];
//  [self.tabBar addSubview:_badgeLabel];

}

- (BOOL) tabBarController:(UITabBarController*)tabBarController shouldSelectViewController:(UIViewController*)viewController
{
  
  if ([viewController.title isEqualToString:@"HOME"])
  {
    [self moveTealShadowLineToItem:0];
  }
  else if([viewController.title isEqualToString:@"FILES"])
  {
    [self moveTealShadowLineToItem:1];
  }
  else if([viewController.title isEqualToString:@"SEND"])
  {
    //Adjust the teal thing.

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"SendNavigationController"];
    navigationController.hidesBottomBarWhenPushed = YES;
    [self presentViewController:navigationController animated:YES completion:nil];
    return NO;
  }
  else if ([viewController.title isEqualToString:@"CONTACTS"])
  {
    [self moveTealShadowLineToItem:3];
  }
  else if([viewController.title isEqualToString:@"SETTINGS"])
  {
    [self moveTealShadowLineToItem:4];
    [self dismissViewControllerAnimated:YES completion:nil];
    return NO;
  }
  return YES;
}

-(void)moveTealShadowLineToItem:(NSInteger)itemNumber
{
  _tealShadowLine.frame = CGRectMake(itemNumber * 64, 0, 64, 1);
}




@end
