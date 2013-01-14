//
//  RCIOItem+Private.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItem.h"

@class RACScheduler;

#if DEBUG
#define ASSERT_FILE_SYSTEM_SCHEDULER() ASSERT(currentScheduler() == fileSystemScheduler())
#else
#define ASSERT_FILE_SYSTEM_SCHEDULER()
#endif

// All filesystem accesses must be on this scheduler.
RACScheduler *fileSystemScheduler();

// All values sent by returned signals must be sent on the calling scheduler.
RACScheduler *currentScheduler();

// Accesses to the cache must be on `fileSystemScheduler()`.
NSMutableDictionary *fileSystemItemCache();

@interface RCIOItem ()

@property (atomic, strong) NSURL *urlBacking;

// Returns the item at `url` or nil.
//
// Must be called on `fileSystemScheduler()`
+ (instancetype)loadItemFromURL:(NSURL *)url;

// Designated initializer.
//
// There shouldn't necessarily be something to load from `url`, nor should the
// item write anything to it at first.
//
// Must be called on `fileSystemScheduler()`
- (instancetype)initWithURL:(NSURL *)url;

// Called after the receiver has been created.
//
// Must be called on `fileSystemScheduler()`
- (void)didCreate;

// Called after the receiver has been moved.
//
// Must be called on `fileSystemScheduler()`
- (void)didMoveToURL:(NSURL *)url;

// Called after the receiver has been copied.
//
// Must be called on `fileSystemScheduler()`
- (void)didCopyToURL:(NSURL *)url;

// Called after the receiver has been deleted.
//
// Must be called on `fileSystemScheduler()`
- (void)didDelete;

@end
