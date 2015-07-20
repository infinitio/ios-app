//
//  UICollectionView+Convenience.m
//  Infinit
//
//  Created by Christopher Crone on 18/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "UICollectionView+Convenience.h"

@implementation UICollectionView (infinit_Convenience)

- (NSArray*)infinit_indexPathsForElementsInRect:(CGRect)rect
{
  NSArray* all_layout_attrs = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
  if (all_layout_attrs.count == 0)
    return nil;
  NSMutableArray* indexes = [NSMutableArray arrayWithCapacity:all_layout_attrs.count];
  for (UICollectionViewLayoutAttributes* attrs in all_layout_attrs)
  {
    NSIndexPath* index = attrs.indexPath;
    [indexes addObject:index];
  }
  return indexes;
}

@end
