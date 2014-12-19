//
//  InfCollectionViewCell.m
//  Infinit
//
//  Created by Michael Dee on 6/30/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfCollectionViewCell.h"

@implementation InfCollectionViewCell


- (id)initWithFrame:(CGRect)frame
{

  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
/*
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    
    UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.contentView]];
    [self.animator addBehavior:gravityBehavior];
    
    UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.contentView]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:collisionBehavior];
    
    UIDynamicItemBehavior *elasticityBehavior =
    [[UIDynamicItemBehavior alloc] initWithItems:@[self.contentView]];
    elasticityBehavior.elasticity = 0.5f;
    [self.animator addBehavior:elasticityBehavior];
 */

     
    
    _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    
    _blackLayer = [[UIView alloc] initWithFrame:self.contentView.frame];
    _blackLayer.backgroundColor = [UIColor blackColor];
    _blackLayer.alpha = .5;
    
    _checkMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-checked.png"]];
    _checkMark.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    [self.contentView addSubview:_imageView];
    [self.contentView addSubview:_blackLayer];
    [self.contentView addSubview:_checkMark];
    
    CGRect durationFrame = CGRectMake(70, 86, 40, 18);
    _durationLabel = [[UILabel alloc] initWithFrame:durationFrame];
    _durationLabel.textColor = [UIColor whiteColor];
    _durationLabel.font = [UIFont boldSystemFontOfSize:12];
    
  }
  return self;
}



- (void)prepareForReuse
{
//  [_animator removeAllBehaviors];
  _imageView.image = nil;
  _durationLabel.text = nil;

}

@end
