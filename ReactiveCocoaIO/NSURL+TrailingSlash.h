//
//  NSURL+TrailingSlash.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 20/01/2013.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (TrailingSlash)

- (BOOL)hasTrailingSlash;
- (NSURL *)URLByAppendingTrailingSlash;
- (NSURL *)URLByDeletingTrailingSlash;

@end
