//
//  RCIOItem.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 9/26/12.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItem+Private.h"

#import <sys/xattr.h>

#import "NSURL+TrailingSlash.h"
#import "RCIODirectory+Private.h"
#import "RCIOWeakDictionary.h"

// Access the cache of existing RCIOItems, used for uniquing
static void accessItemCache(void (^block)(RCIOWeakDictionary *itemCache)) {
	NSCAssert(block != nil, @"Passed nil block to accessItemCache");
	static RCIOWeakDictionary *itemCache = (id)@"";
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		itemCache = [RCIOWeakDictionary dictionary];
	});
	
	@synchronized(itemCache) {
		block(itemCache);
	}
}

@interface RCIOItem ()

// A dictionary of `RACChannelTerminal`s mapped to their extended attribute
// names.
//
// Must be accessed while synchronized on self.
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

@end

@interface RCIOItem (ExtendedAttributes_Private)

- (id)loadXattrValueForKey:(NSString *)key;
- (void)saveXattrValue:(id)value forKey:(NSString *)key;

@end

@implementation RCIOItem

#pragma mark RCIOItem

+ (RACSignal *)itemWithURL:(NSURL *)url mode:(RCIOItemMode)mode {
	if (!url.isFileURL) return [RACSignal error:[NSError errorWithDomain:@"RCIOErrorDomain" code:-1 userInfo:nil]];
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [[RACScheduler scheduler] schedule:^{
			NSURL *resolvedURL = url.URLByResolvingSymlinksInPath;
			__block RCIOItem *item = nil;
			
			accessItemCache(^(RCIOWeakDictionary *itemCache) {
				if ([[[NSFileManager alloc] init] fileExistsAtPath:resolvedURL.path]) {
					if (mode & RCIOItemModeExclusiveAccess) {
						[subscriber sendError:[NSError errorWithDomain:@"RCIOErrorDomain" code:-1 userInfo:nil]];
						return;
					}
					item = [self loadItemFromURL:resolvedURL];
				} else {
					item = [self createItemAtURL:resolvedURL];
					[item didCreate];
				}
				
				if (item != nil) itemCache[resolvedURL.URLByDeletingTrailingSlash] = item;
			});
			
			if (item != nil && [item isKindOfClass:self]) {
				[subscriber sendNext:item];
				[subscriber sendCompleted];
			} else {
				[subscriber sendError:[NSError errorWithDomain:@"RCIOErrorDomain" code:-1 userInfo:nil]];
			}
		}];
	}];
}

+ (RACSignal *)itemWithURL:(NSURL *)url {
	return [self itemWithURL:url mode:RCIOItemModeReadWrite];
}

+ (instancetype)createItemAtURL:(NSURL *)url {
	return nil;
}

+ (instancetype)loadItemFromURL:(NSURL *)url {
	Class class = Nil;
	NSString *detectedType = nil;
	
	__block RCIOItem *item = nil;
	accessItemCache(^(RCIOWeakDictionary *itemCache) {
		item = itemCache[url.URLByDeletingTrailingSlash];
	});
	if (item != nil) return item;
	
	[url getResourceValue:&detectedType forKey:NSURLFileResourceTypeKey error:NULL];
	if (detectedType == NSURLFileResourceTypeRegular) {
		class = [RCIOFile class];
		url = url.URLByDeletingTrailingSlash;
	} else if (detectedType == NSURLFileResourceTypeDirectory) {
		class = [RCIODirectory class];
		url = url.URLByAppendingTrailingSlash;
	}
	
	return [[class alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
	NSParameterAssert(url.isFileURL);
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_urlBacking = url;
	_extendedAttributesBacking = [NSMutableDictionary dictionary];
	
	return self;
}

- (NSURL *)url {
	return self.urlBacking;
}

- (RACSignal *)urlSignal {
	return RACObserve(self, urlBacking);
}

- (RACSignal *)parentSignal {
	return [[self.urlSignal map:^(NSURL *value) {
		return [RCIOItem itemWithURL:value.URLByDeletingLastPathComponent];
	}] switchToLatest];
}

- (void)didCreate {
	NSCAssert(self.urlBacking != nil, @"Created an item with a nil URL.");
	
	NSURL *url = self.urlBacking;
	__block RCIODirectory *parent = nil;
	accessItemCache(^(RCIOWeakDictionary *itemCache) {
		parent = itemCache[url.URLByDeletingLastPathComponent.URLByDeletingTrailingSlash];
	});
	[parent didAddItem:self];
}

- (void)didMoveToURL:(NSURL *)url {
	NSURL *fromURL = self.urlBacking;
	__block RCIODirectory *fromParent = nil;
	__block RCIODirectory *toParent = nil;
	accessItemCache(^(RCIOWeakDictionary *itemCache) {
		fromParent = itemCache[fromURL.URLByDeletingLastPathComponent.URLByDeletingTrailingSlash];
		toParent = itemCache[url.URLByDeletingLastPathComponent.URLByDeletingTrailingSlash];
		[itemCache removeObjectForKey:fromURL.URLByDeletingTrailingSlash];
		self.urlBacking = url;
		itemCache[url.URLByDeletingTrailingSlash] = self;
	});
	if (fromParent == toParent) return;
	if ([fromParent isKindOfClass:RCIODirectory.class]) [fromParent didRemoveItem:self];
	if ([toParent isKindOfClass:RCIODirectory.class]) [toParent didAddItem:self];
}

- (void)didCopyToURL:(NSURL *)url {
	__block RCIODirectory *toParent = nil;
	accessItemCache(^(RCIOWeakDictionary *itemCache) {
		toParent = itemCache[url.URLByDeletingLastPathComponent.URLByDeletingTrailingSlash];
		itemCache[url.URLByDeletingTrailingSlash] = self;
	});
	if ([toParent isKindOfClass:RCIODirectory.class]) [toParent didAddItem:self];
}

- (void)didDelete {
	NSURL *fromURL = self.urlBacking;
	__block RCIODirectory *fromParent =nil;
	accessItemCache(^(RCIOWeakDictionary *itemCache) {
		fromParent = itemCache[fromURL.URLByDeletingLastPathComponent.URLByDeletingTrailingSlash];
		[itemCache removeObjectForKey:fromURL.URLByDeletingTrailingSlash];
		self.urlBacking = nil;
	});
	if ([fromParent isKindOfClass:RCIODirectory.class]) [fromParent didRemoveItem:self];
}

@end

@implementation RCIOItem (FileManagement)

- (RACSignal *)moveTo:(RCIODirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	RACSubject *subject = [RACReplaySubject subject];
	
	[[RACScheduler scheduler] schedule:^{
		NSURL *url = self.urlBacking;
		NSURL *destinationURL = url;
		
		if (destinationURL != nil) {
			if (destination != nil) destinationURL = [destination.urlBacking URLByAppendingPathComponent:destinationURL.lastPathComponent];
			if (newName != nil) destinationURL = [destinationURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:newName];
		}
		
		if (![url isEqual:destinationURL]) {
			NSError *error = nil;
			
			if (url == nil) {
				[subject sendError:[NSError errorWithDomain:@"RCIOErrorDomain" code:-1 userInfo:nil]];
				return;
			}
			if (shouldReplace && [[[NSFileManager alloc] init] fileExistsAtPath:destinationURL.path]) {
				if ([[[NSFileManager alloc] init] removeItemAtURL:destinationURL error:&error]) {
					accessItemCache(^(RCIOWeakDictionary *itemCache) {
						[itemCache[destinationURL.URLByDeletingTrailingSlash] didDelete];
					});
				}
			}
			if (![[[NSFileManager alloc] init] moveItemAtURL:url toURL:destinationURL error:&error]) {
				[subject sendError:error];
				return;
			}
		}
		
		[self didMoveToURL:destinationURL];
		[subject sendNext:self];
		[subject sendCompleted];
	}];
	
	return subject;
}

- (RACSignal *)copyTo:(RCIODirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	RACSubject *subject = [RACReplaySubject subject];
	
	[[RACScheduler scheduler] schedule:^{
		NSURL *url = self.urlBacking;
		NSURL *destinationURL = url;
		
		if (destinationURL != nil) {
			if (destination != nil) destinationURL = [destination.urlBacking URLByAppendingPathComponent:destinationURL.lastPathComponent];
			if (newName != nil) destinationURL = [destinationURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:newName];
		}
		
		if (![url isEqual:destinationURL]) {
			NSError *error = nil;
			
			if (url == nil) {
				[subject sendError:[NSError errorWithDomain:@"RCIOErrorDomain" code:-1 userInfo:nil]];
				return;
			}
			if (shouldReplace && [[[NSFileManager alloc] init] fileExistsAtPath:destinationURL.path]) {
				if ([[[NSFileManager alloc] init] removeItemAtURL:destinationURL error:&error]) {
					accessItemCache(^(RCIOWeakDictionary *itemCache) {
						[itemCache[destinationURL.URLByDeletingTrailingSlash] didDelete];
					});
				}
			}
			if (![[[NSFileManager alloc] init] copyItemAtURL:url toURL:destinationURL error:&error]) {
				[subject sendError:error];
				return;
			}
		}
		
		RCIOItem *item = [RCIOItem loadItemFromURL:destinationURL];
		if (item == nil) {
			[subject sendError:[NSError errorWithDomain:@"RCIOErrorDomain" code:-1 userInfo:nil]];
			return;
		}
		
		[item didCopyToURL:destinationURL];
		[subject sendNext:item];
		[subject sendCompleted];
	}];
	
	return subject;
}

- (RACSignal *)moveTo:(RCIODirectory *)destination {
	return [self moveTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)copyTo:(RCIODirectory *)destination {
	return [self copyTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)renameTo:(NSString *)newName {
	return [self moveTo:nil withName:newName replaceExisting:YES];
}

- (RACSignal *)duplicate {
	RACSubject *subject = [RACReplaySubject subject];
	
	[[RACScheduler scheduler] schedule:^{
		NSURL *url = self.urlBacking;
		NSUInteger duplicateCount = 1;
		NSURL *destinationURL = nil;
		NSError *error = nil;
		
		for (;;) {
			destinationURL = [url.URLByDeletingLastPathComponent URLByAppendingPathComponent:(url.pathExtension.length == 0 ? [NSString stringWithFormat:@"%@ (%@)", url.lastPathComponent, @(duplicateCount)] : [NSString stringWithFormat:@"%@ (%@).%@", url.lastPathComponent.stringByDeletingPathExtension, @(duplicateCount), url.pathExtension])];
			if (![[[NSFileManager alloc] init] fileExistsAtPath:destinationURL.path]) break;
			++duplicateCount;
		}
		if (![[[NSFileManager alloc] init] copyItemAtURL:url toURL:destinationURL error:&error]) {
			[subject sendError:error];
		} else {
			RCIOItem *duplicate = [[self.class alloc] initWithURL:destinationURL];
			[duplicate didCopyToURL:destinationURL];
			[subject sendNext:duplicate];
			[subject sendCompleted];
		}
	}];
	
	return subject;
}

- (RACSignal *)delete {
	RACSubject *subject = [RACReplaySubject subject];
	
	[[RACScheduler scheduler] schedule:^{
		NSURL *url = self.urlBacking;
		NSError *error = nil;
		
		if (![[[NSFileManager alloc] init] removeItemAtURL:url error:&error]) {
			[subject sendError:error];
		} else {
			[self didDelete];
			[subject sendNext:self];
			[subject sendCompleted];
		}
	}];
	return subject;
}

@end

@implementation RCIOItem (ExtendedAttributes)

- (RACChannelTerminal *)extendedAttributeChannelForKey:(NSString *)key {
	@weakify(self);
	
	@synchronized (self) {
		RACChannel *channel = self.extendedAttributesBacking[key];
		if (channel != nil) return channel.followingTerminal;

		channel = [[RACChannel alloc] init];

		RACSignal *values = [[RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
			[[RACScheduler scheduler] schedule:^{
				@strongify(self);
				if (self == nil) return;
				id value = [self loadXattrValueForKey:key];
				[subscriber sendNext:value];
				[subscriber sendCompleted];
			}];
			return nil;
		}] concat:channel.leadingTerminal];
		[values subscribe:channel.leadingTerminal];

		[channel.leadingTerminal subscribeNext:^(id x) {
			[[RACScheduler scheduler] schedule:^{
				@strongify(self);
				if (self == nil) return;
				[self saveXattrValue:x forKey:key];
			}];
		}];

		self.extendedAttributesBacking[key] = channel;
		return channel.followingTerminal;
	}
}

@end

@implementation RCIOItem (ExtendedAttributes_Private)

static size_t _xattrMaxSize = 4 * 1024; // 4 kB

- (id)loadXattrValueForKey:(NSString *)key {
	id xattrValue = nil;
	void *xattrBytes = malloc(_xattrMaxSize);
	ssize_t xattrBytesCount = getxattr(self.urlBacking.path.fileSystemRepresentation, key.UTF8String, xattrBytes, _xattrMaxSize, 0, 0);
	if (xattrBytesCount != -1) {
		NSData *xattrData = [NSData dataWithBytes:xattrBytes length:xattrBytesCount];
		xattrValue = [NSKeyedUnarchiver unarchiveObjectWithData:xattrData];
	}
	free(xattrBytes);
	return xattrValue;
}

- (void)saveXattrValue:(id)value forKey:(NSString *)key {
	if (self.urlBacking == nil) return;
	if (value) {
		NSData *xattrData = [NSKeyedArchiver archivedDataWithRootObject:value];
		setxattr(self.urlBacking.path.fileSystemRepresentation, key.UTF8String, [xattrData bytes], [xattrData length], 0, 0);
	} else {
		removexattr(self.urlBacking.path.fileSystemRepresentation, key.UTF8String, 0);
	}
}

@end
