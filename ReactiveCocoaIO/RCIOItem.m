//
//  RCIOItem.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 9/26/12.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import "RCIOItem+Private.h"

#import <ReactiveCocoa/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <sys/xattr.h>

#import "NSURL+TrailingSlash.h"
#import "RCIODirectory+Private.h"
#import "RCIOFile.h"
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

@implementation RCIOItem (ExtendedAttributes)

- (RACChannelTerminal *)extendedAttributeChannelForKey:(NSString *)key {
	@weakify(self);
	
	@synchronized (self) {
		RACChannel *channel = self.extendedAttributesBacking[key];
		if (channel != nil) return channel.followingTerminal;

		channel = [[RACChannel alloc] init];
		RACSubject *backing = [RACSubject subject];

		RACSignal *values = [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
			[[RACScheduler scheduler] schedule:^{
				@strongify(self);
				if (self == nil) return;
				id value = [self loadXattrValueForKey:key];
				[subscriber sendNext:value];
				[subscriber sendCompleted];
			}];
			return (RACDisposable *)nil;
		}] concat:backing];
		[values subscribe:channel.leadingTerminal];

		[channel.leadingTerminal subscribeNext:^(id x) {
			[[RACScheduler scheduler] schedule:^{
				@strongify(self);
				if (self == nil) return;
				[self saveXattrValue:x forKey:key];
				[backing sendNext:x];
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
