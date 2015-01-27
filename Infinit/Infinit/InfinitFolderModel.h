//
//  InfinitFolderModel.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@interface InfinitFolderModel : NSObject

@property (nonatomic, readonly) NSNumber* ctime;
@property (nonatomic, readonly) NSArray* files;
@property (nonatomic, readonly) UIImage* thumbnail;
@property (nonatomic, readonly) NSNumber* size;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* sender_meta_id;
@property (nonatomic, readwrite) NSString* sender_name;

- (id)initWithPath:(NSString*)path;

- (void)deleteFileAtIndex:(NSInteger)index;
- (void)deleteFolder;

@end