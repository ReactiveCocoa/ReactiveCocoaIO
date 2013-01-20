//
//  NSURL+TrailingSlash.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 20/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "NSURL+TrailingSlash.h"

@implementation NSURL (TrailingSlash)

- (BOOL)hasTrailingSlash {
	NSParameterAssert(self.isFileURL);
	return [self.absoluteString hasSuffix:@"/"];
}

- (NSURL *)URLByAppendingTrailingSlash {
	NSParameterAssert(self.isFileURL);
	NSURL *url = self;
	if (!self.hasTrailingSlash) url = [NSURL fileURLWithPath:[url.path stringByAppendingString:@"/"]];
	return url;
}

- (NSURL *)URLByDeletingTrailingSlash {
	NSParameterAssert(self.isFileURL);
	NSURL *url = self;
	if (self.hasTrailingSlash) url = [NSURL fileURLWithPath:[url.path substringToIndex:url.path.length - 1]];
	return url;
}

@end
