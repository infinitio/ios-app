//
//  InfinitFilesTableCell.m
//  Infinit
//
//  Created by Christopher Crone on 24/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesTableCell.h"

@import AVFoundation;

@implementation InfinitFilesTableCell

- (void)configureCellForPath:(NSString*)path
{
  self.name_label.text = path.lastPathComponent;
}

@end
