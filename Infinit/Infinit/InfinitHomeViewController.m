//
//  InfinitHomeViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/18/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitHomeViewController.h"

@interface InfinitHomeViewController ()

@end

@implementation InfinitHomeViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
