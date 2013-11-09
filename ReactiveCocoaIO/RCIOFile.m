//
//  RCIOFile.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import "RCIOFile.h"
#import "RCIOItem+Private.h"

#import "NSURL+TrailingSlash.h"

@implementation RCIOFile

#pragma mark RCIOItem

+ (instancetype)createItemAtURL:(NSURL *)url {
	if (![@"" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:NULL]) return nil;
	return [[self alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
	url = url.URLByDeletingTrailingSlash;
	
	self = [super initWithURL:url];
	if (self == nil) return nil;
	
	return self;
}

- (void)didMoveToURL:(NSURL *)url {
	url = url.URLByDeletingTrailingSlash;
	[super didMoveToURL:url];
}

- (void)didCopyToURL:(NSURL *)url {
	url = url.URLByDeletingTrailingSlash;
	[super didCopyToURL:url];
}

@end
