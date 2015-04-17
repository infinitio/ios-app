//
//  InfinitFilesSearchPopover_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesSearchPopover_iPad.h"

@interface InfinitFilesSearchPopover_iPad () <UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar* search_bar;

@end

@implementation InfinitFilesSearchPopover_iPad

- (void)viewDidLoad
{
  [super viewDidLoad];
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 1.0f), NO, 0.0f);
  [[UIColor whiteColor] set];
  CGContextFillRect(UIGraphicsGetCurrentContext(), self.search_bar.bounds);
  UIImage* search_bar_bg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.search_bar.backgroundImage = search_bar_bg;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.search_bar becomeFirstResponder];
}

- (NSString*)search_string
{
  return self.search_bar.text;
}

- (void)setSearch_string:(NSString*)search_string
{
  self.search_bar.text = search_string;
}

- (void)searchBar:(UISearchBar*)searchBar
    textDidChange:(NSString*)searchText
{
  [self.delegate searchView:self stringDidChange:searchText];
}

@end
