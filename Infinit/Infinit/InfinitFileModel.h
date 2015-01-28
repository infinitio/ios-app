//
//  InfinitFileModel.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

#import "InfinitFilePreview.h"

@interface InfinitFileModel : NSObject

@property (nonatomic, readonly) CGFloat duration;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* path;
@property (nonatomic, readonly) NSNumber* size;
@property (nonatomic, readwrite) UIImage* thumbnail;
@property (nonatomic, readonly) InfinitFileTypes type;

- (id)initWithPath:(NSString*)path
           andSize:(NSNumber*)size;

@end
