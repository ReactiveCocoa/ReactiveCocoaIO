//
//  RCIOItem+Private.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItem.h"

@class RACScheduler;

@interface RCIOItem ()

@property (atomic, strong) NSURL *urlBacking;

// Returns a newly created item at `url` or nil.
+ (instancetype)createItemAtURL:(NSURL *)url;

// Returns the item at `url` or nil.
+ (instancetype)loadItemFromURL:(NSURL *)url;

// Designated initializer.
//
// There shouldn't necessarily be something to load from `url`, nor should the
// item write anything to it at first.
- (instancetype)initWithURL:(NSURL *)url;

// Called after the receiver has been created.
- (void)didCreate;

// Called after the receiver has been moved.
- (void)didMoveToURL:(NSURL *)url;

// Called after the receiver has been copied.
- (void)didCopyToURL:(NSURL *)url;

// Called after the receiver has been deleted.
- (void)didDelete;

@end
