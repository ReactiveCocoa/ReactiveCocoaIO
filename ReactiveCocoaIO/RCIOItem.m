//
//  RCIOItem.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 9/26/12.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItem+Private.h"

#import <sys/xattr.h>

#import "RCIODirectory+Private.h"
#import "RCIOFile.h"

// Scheduler for serializing accesses to the file system
RACScheduler *fileSystemScheduler() {
  static RACScheduler *fileSystemScheduler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
		fileSystemScheduler = [RACScheduler scheduler];
  });
  return fileSystemScheduler;
}

// Returns the current scheduler
RACScheduler *currentScheduler() {
	NSCAssert(RACScheduler.currentScheduler != nil, @"ReactiveCocoaIO called from a thread without a RACScheduler.");
  return RACScheduler.currentScheduler;
}

// Cache of existing RCIOItems, used for uniquing
NSMutableDictionary *fileSystemItemCache() {
  ASSERT_FILE_SYSTEM_SCHEDULER();
  static NSMutableDictionary *itemCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    itemCache = [NSMutableDictionary dictionary];
  });
  return itemCache;
}

@interface RCIOItem ()

// A dictionary of `RACPropertySubject`s mapped to their extended attribute
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

+ (RACSignal *)itemWithURL:(NSURL *)url {
	if (![url isFileURL]) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		return [fileSystemScheduler() schedule:^{
			RCIOItem *item = fileSystemItemCache()[url];
			if (item == nil) {
				item = [self loadItemFromURL:url];
				if (item == nil && self != RCIOItem.class) item = [[self alloc] initWithURL:url];
				if (item != nil) fileSystemItemCache()[url] = item;
			}
			
			if (item != nil) {
				if ([item isKindOfClass:self]) {
					[subscriber sendNext:item];
					[subscriber sendCompleted];
				} else {
					[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
				}
			}
		}];
	}] deliverOn:currentScheduler()];
}

+ (instancetype)loadItemFromURL:(NSURL *)url {
	Class class = Nil;
	NSString *detectedType = nil;
	
	[url getResourceValue:&detectedType forKey:NSURLFileResourceTypeKey error:NULL];
	if (detectedType == NSURLFileResourceTypeRegular) {
		class = [RCIOFile class];
	} else if (detectedType == NSURLFileResourceTypeDirectory) {
		class = [RCIODirectory class];
	}
	
	return [[class alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
  ASSERT_FILE_SYSTEM_SCHEDULER();
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
  return [RACAbleWithStart(self.urlBacking) deliverOn:currentScheduler()];
}

- (NSString *)name {
	return self.urlBacking.lastPathComponent;
}

- (RACSignal *)nameSignal {
  return [self.urlSignal map:^NSString *(NSURL *url) {
    return url.lastPathComponent;
  }];
}

- (RACSignal *)parent {
	return [[self.urlSignal map:^(NSURL *value) {
		return [RCIOItem itemWithURL:value.URLByDeletingLastPathComponent];
	}] switchToLatest];
}

- (void)didCreate {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	NSAssert(self.urlBacking != nil, @"Created an item with a nil URL.");
	
	NSURL *url = self.urlBacking;
	
	RCIODirectory *parent = fileSystemItemCache()[url.URLByDeletingLastPathComponent];
	[parent didAddItem:self];
}

- (void)didMoveToURL:(NSURL *)url {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	NSURL *fromURL = self.urlBacking;
	
	RCIODirectory *fromParent = fileSystemItemCache()[fromURL.URLByDeletingLastPathComponent];
	if ([fromParent isKindOfClass:RCIODirectory.class]) [fromParent didRemoveItem:self];
	
	[fileSystemItemCache() removeObjectForKey:fromURL];
	self.urlBacking = url;
	fileSystemItemCache()[url] = self;
	
	RCIODirectory *toParent = fileSystemItemCache()[url.URLByDeletingLastPathComponent];
	if ([toParent isKindOfClass:RCIODirectory.class]) [toParent didAddItem:self];
}

- (void)didCopyToURL:(NSURL *)url {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	
	fileSystemItemCache()[url] = self;
	
	RCIODirectory *toParent = fileSystemItemCache()[url.URLByDeletingLastPathComponent];
	if ([toParent isKindOfClass:RCIODirectory.class]) [toParent didAddItem:self];
}

- (void)didDelete {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	NSURL *fromURL = self.urlBacking;
	
	RCIODirectory *fromParent = fileSystemItemCache()[fromURL.URLByDeletingLastPathComponent];
	if ([fromParent isKindOfClass:RCIODirectory.class]) [fromParent didRemoveItem:self];
	
	[fileSystemItemCache() removeObjectForKey:fromURL];
	self.urlBacking = nil;
}

#pragma mark NSObject

#ifdef DEBUG
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
	if ([keyPath isEqualToString:@keypath(self.url)] || [keyPath isEqualToString:@keypath(self.name)]) {
		ASSERT_FILE_SYSTEM_SCHEDULER();
	}
	[super addObserver:observer forKeyPath:keyPath options:options context:context];
}
#endif

@end

@implementation RCIOItem (FileManagement)

- (RACSignal *)create {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	@weakify(self);
	
	NSMutableArray *signals = [NSMutableArray array];
	@synchronized (self) {
		[self.extendedAttributesBacking enumerateKeysAndObjectsUsingBlock:^(NSString *key, RACPropertySubject *extendedAttribute, BOOL *stop) {
			[signals addObject:[[extendedAttribute take:1] map:^(id value) {
				return [RACTuple tupleWithObjects:key, value, nil];
			}]];
		}];
	}
	
	if (signals.count == 0) return [[RACSignal return:self] doNext:^(id x) {
		[self didCreate];
	}];
	
	return [[RACSignal zip:signals] map:^(RACTuple *tuples) {
		@strongify(self);
		
		for (RACTuple *tuple in tuples) {
			RACTupleUnpack(NSString *key, id value) = tuple;
			[self saveXattrValue:value forKey:key];
		}
		
		[self didCreate];
		return self;
	}];
}

- (RACSignal *)moveTo:(RCIODirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		return [fileSystemScheduler() schedule:^{
			@strongify(self);
			
			NSURL *url = self.urlBacking;
			NSURL *destinationURL = [destination.urlBacking URLByAppendingPathComponent:newName ?: url.lastPathComponent];
			NSError *error = nil;
			
			if (shouldReplace && [NSFileManager.defaultManager fileExistsAtPath:destinationURL.path]) {
				[NSFileManager.defaultManager removeItemAtURL:destinationURL error:&error];
			}
			if (![NSFileManager.defaultManager moveItemAtURL:url toURL:destinationURL error:&error]) {
				[subscriber sendError:error];
			} else {
				[self didMoveToURL:destinationURL];
				[subscriber sendNext:self];
				[subscriber sendCompleted];
			}
		}];
	}] deliverOn:currentScheduler()];
}

- (RACSignal *)copyTo:(RCIODirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		return [fileSystemScheduler() schedule:^{
			@strongify(self);
			
			NSURL *url = self.urlBacking;
			NSURL *destinationURL = [destination.urlBacking URLByAppendingPathComponent:newName ?: url.lastPathComponent];
			NSError *error = nil;
			
			if (shouldReplace && [NSFileManager.defaultManager fileExistsAtPath:destinationURL.path]) {
				[NSFileManager.defaultManager removeItemAtURL:destinationURL error:&error];
			}
			if (![NSFileManager.defaultManager copyItemAtURL:url toURL:destinationURL error:&error]) {
				[subscriber sendError:error];
			} else {
				RCIOItem *copy = [[self.class alloc] initWithURL:destinationURL];
				[copy didCopyToURL:destinationURL];
				[subscriber sendNext:copy];
				[subscriber sendCompleted];
			}
		}];
	}] deliverOn:currentScheduler()];
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
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		return [fileSystemScheduler() schedule:^{
			@strongify(self);
			
			NSURL *url = self.urlBacking;
			NSUInteger duplicateCount = 1;
			NSURL *destinationURL = nil;
			NSError *error = nil;
			
			for (;;) {
				destinationURL = [url.URLByDeletingLastPathComponent URLByAppendingPathComponent:(url.pathExtension.length == 0 ? [NSString stringWithFormat:@"%@ (%@)", url.lastPathComponent, @(duplicateCount)] : [NSString stringWithFormat:@"%@ (%@).%@", url.lastPathComponent.stringByDeletingPathExtension, @(duplicateCount), url.pathExtension])];
				if (![NSFileManager.defaultManager fileExistsAtPath:destinationURL.path]) break;
				++duplicateCount;
			}
			if (![NSFileManager.defaultManager copyItemAtURL:url toURL:destinationURL error:&error]) {
				[subscriber sendError:error];
			} else {
				RCIOItem *duplicate = [[self.class alloc] initWithURL:destinationURL];
				[duplicate didCopyToURL:destinationURL];
				[subscriber sendNext:duplicate];
				[subscriber sendCompleted];
			}
		}];
	}] deliverOn:currentScheduler()];
}

- (RACSignal *)delete {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		return [fileSystemScheduler() schedule:^{
			@strongify(self);
			
			NSURL *url = self.urlBacking;
			NSError *error = nil;
			
			if (![NSFileManager.defaultManager removeItemAtURL:url error:&error]) {
				[subscriber sendError:error];
			} else {
				[self didDelete];
				[subscriber sendNext:self];
				[subscriber sendCompleted];
			}
		}];
	}] deliverOn:currentScheduler()];
}

@end

@implementation RCIOItem (ExtendedAttributes)

- (RACPropertySubject *)extendedAttributeSubjectForKey:(NSString *)key {
	@weakify(self);
	
	@synchronized (self) {
		RACPropertySubject *subject = self.extendedAttributesBacking[key];
		if (subject != nil) return subject;
		
		subject = [RACPropertySubject property];
			
		// Load the initial value from the filesystem
		[fileSystemScheduler() schedule:^{
			@strongify(self);
			id value = [self loadXattrValueForKey:key];
			if (value)[subject sendNext:value];
		}];
		
		// Save the value to disk every time it changes
		[[subject deliverOn:fileSystemScheduler()] subscribeNext:^(id value) {
			@strongify(self);
			[self saveXattrValue:value forKey:key];
		}];
		
		self.extendedAttributesBacking[key] = subject;
		return subject;
	}
}

@end

@implementation RCIOItem (ExtendedAttributes_Private)

static size_t _xattrMaxSize = 4 * 1024; // 4 kB

- (id)loadXattrValueForKey:(NSString *)key {
	ASSERT_FILE_SYSTEM_SCHEDULER();

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
	ASSERT_FILE_SYSTEM_SCHEDULER();
	
	if (self.urlBacking == nil) return;
	
	if (value) {
		NSData *xattrData = [NSKeyedArchiver archivedDataWithRootObject:value];
		setxattr(self.urlBacking.path.fileSystemRepresentation, key.UTF8String, [xattrData bytes], [xattrData length], 0, 0);
	} else {
		removexattr(self.urlBacking.path.fileSystemRepresentation, key.UTF8String, 0);
	}
}

@end

