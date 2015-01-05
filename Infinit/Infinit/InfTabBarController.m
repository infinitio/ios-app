//
//  InfTabBarController.m
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfTabBarController.h"

@interface InfTabBarController () 

@property (nonatomic, strong) UIView* teal_shadow_line;

@end

@implementation InfTabBarController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.delegate = self;
  
  self.tabBar.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];

  [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
  [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
  [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:8], NSFontAttributeName, nil] forState:UIControlStateNormal];
  
  UIView* shadowLine =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
  shadowLine.backgroundColor = [UIColor grayColor];
  shadowLine.alpha = .5;
  [self.tabBar addSubview:shadowLine];
  
  _teal_shadow_line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 1)];
  _teal_shadow_line.backgroundColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];
  [self.tabBar addSubview:_teal_shadow_line];
  
  // Add the sendImage over the bar button item.
  UIImageView* sendBgImage =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send-bg"]];
  sendBgImage.center = CGPointMake(160, 22);
  [self.tabBar addSubview:sendBgImage];
  
  UIImageView* sendImage =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send"]];
  sendImage.center = CGPointMake(160, 27);
  [self.tabBar addSubview:sendImage];
  
  //Check for the badge items here.  Not yet
  _badge_label = [[TabBarBadgeLabel alloc] initWithFrame:CGRectMake(0, 0, 16, 16)
                                                 onItem:0
                                              withBadge:4];
//  [self.tabBar addSubview:_badge_label];

}

- (BOOL) tabBarController:(UITabBarController*)tabBarController shouldSelectViewController:(UIViewController*)viewController
{
  
  if ([viewController.title isEqualToString:@"HOME"])
  {
    [self teal_shadow_lineToItem:0];
  }
  else if([viewController.title isEqualToString:@"FILES"])
  {
    [self teal_shadow_lineToItem:1];
  }
  else if([viewController.title isEqualToString:@"SEND"])
  {
    //Adjust the teal thing.

    UIStoryboard* storyboard =
      [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController* navigationController =
      [storyboard instantiateViewControllerWithIdentifier:@"SendNavigationController"];
    navigationController.hidesBottomBarWhenPushed = YES;
    [self presentViewController:navigationController animated:YES completion:nil];
    return NO;
  }
  else if ([viewController.title isEqualToString:@"CONTACTS"])
  {
    [self teal_shadow_lineToItem:3];
  }
  else if([viewController.title isEqualToString:@"SETTINGS"])
  {
    [self teal_shadow_lineToItem:4];
    //Should really instantiate and present modally.
//    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIStoryboard* storyboard =
      [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController* viewController =
      [storyboard instantiateViewControllerWithIdentifier:@"welcomeVC"];
    [self presentViewController:viewController animated:YES completion:nil];
    
    return NO;
  }
  return YES;
}

-(void)teal_shadow_lineToItem:(NSInteger)itemNumber
{
  _teal_shadow_line.frame = CGRectMake(itemNumber * 64, 0, 64, 1);
}




@end
