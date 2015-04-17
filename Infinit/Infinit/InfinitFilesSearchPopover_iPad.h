//
//  InfinitFilesSearchPopover_iPad.h
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitFilesSearchProtocol;

@interface InfinitFilesSearchPopover_iPad : UIViewController

@property (nonatomic, readwrite) id<InfinitFilesSearchProtocol> delegate;
@property (nonatomic, readwrite) NSString* search_string;

@end

@protocol InfinitFilesSearchProtocol <NSObject>

- (void)searchView:(InfinitFilesSearchPopover_iPad*)sender
   stringDidChange:(NSString*)string;

@end
