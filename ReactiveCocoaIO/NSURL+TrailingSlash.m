//
//  NSURL+TrailingSlash.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 20/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "NSURL+TrailingSlash.h"

// Can't use +[NSURL fileURLWithPath:] or -[NSURL path] for these because they
// have a lot of magic in them to add / remove trailing slashes depending on
// whether they're pointing to a file or directory.
@implementation NSURL (TrailingSlash)

- (BOOL)hasTrailingSlash {
	NSParameterAssert(self.isFileURL);
	return [self.absoluteString hasSuffix:@"/"];
}

- (NSURL *)URLByAppendingTrailingSlash {
	NSParameterAssert(self.isFileURL);
	NSURL *url = self;
	if (!self.hasTrailingSlash) url = [NSURL URLWithString:[NSString stringWithFormat:@"file://localhost%@/", self.path]];
	return url;
}

- (NSURL *)URLByDeletingTrailingSlash {
	NSParameterAssert(self.isFileURL);
	NSURL *url = self;
	if (self.hasTrailingSlash) url = [NSURL URLWithString:[NSString stringWithFormat:@"file://localhost%@", [url.path substringToIndex:url.path.length]]];
	return url;
}

@end
