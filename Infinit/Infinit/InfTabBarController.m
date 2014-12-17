//
//  InfTabBarController.m
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfTabBarController.h"

@interface InfTabBarController () 


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
  
  self.tabBar.tintColor = [UIColor colorWithRed:43/255.0 green:190/255.0 blue:189/255.0 alpha:1];

  
  // Add the sendImage over the bar button item.
  UIImageView *sendBgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send-bg"]];
  sendBgImage.center = CGPointMake(160, 24);
  [self.tabBar addSubview:sendBgImage];
  
  UIImageView *sendImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send"]];
  sendImage.center = CGPointMake(160, 24);
  [self.tabBar addSubview:sendImage];
  
  //Check for the badge items here.
  _badgeLabel = [[TabBarBadgeLabel alloc] initWithFrame:CGRectMake(0, 0, 16, 16)
                                                 onItem:0
                                              withBadge:4];
  [self.tabBar addSubview:_badgeLabel];

}

- (BOOL) tabBarController:(UITabBarController*)tabBarController shouldSelectViewController:(UIViewController*)viewController
{

  if ([viewController.title isEqualToString:@"Send"])
  {
    //Do the other thing here and return no.
    
    //Push send selection view controller onto the stack.  Animate it up the right way.
    
    //Should really make this a custom COLLECTION VIEW.

  /*
    InfMediaViewController* mediaPicker = [[InfMediaViewController alloc] init];
    mediaPicker.hidesBottomBarWhenPushed = YES;        
    [(UINavigationController*)self.selectedViewController pushViewController:mediaPicker animated:YES];
    
    return NO ;
   */
    return NO;
  }
  return YES ;
}




@end
