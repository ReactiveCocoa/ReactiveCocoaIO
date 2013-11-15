//
//  RCIOFileManager.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import "RCIOFileManager.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

typedef struct {
	__unsafe_unretained NSString const *underlyingError;
	__unsafe_unretained NSString const *fsEventsError;
} RCIOFileManagerErrorMessagesList;

#if TARGET_OS_IPHONE
// The subject that receives all the changes RCIOFileManager makes (iOS only).
static RACSubject *changesBroadcastSubject;
#endif

// Sends a url to `changesBroadcastSubject.
//
// This is declared as an empty function on OS X so we don't have to pepper
// the code with even more conditional compilation.
static void broadcastChange(NSURL *url) {
#if TARGET_OS_IPHONE
	[changesBroadcastSubject sendNext:url];
#endif
}

@interface RCIOFileManager ()

// The list of error messages for errors sent by RCIOFileManager.
+ (RCIOFileManagerErrorMessagesList)errorMessages;

// A signal that observes the specified url for changes.
//
// url   - The url to observe.
// delay - The amount of time to delay the sending of changes to coalesce them
//         together.
//
// Returns a signal that sends arrays of urls descendants of `url` affected by
// changes up to `delay` after the changes happen.
+ (RACSignal *)changesAtURL:(NSURL *)url delayedUpTo:(NSTimeInterval)delay;

@end

@implementation RCIOFileManager

#if TARGET_OS_IPHONE
+ (void)initialize {
	changesBroadcastSubject = [RACSubject subject];
}
#endif

+ (NSString *)errorDomain {
	return @"RCIOFileManagerErrorDomain";
}

+ (RCIOFileManagerErrorCodesList)errorCodes {
	return (RCIOFileManagerErrorCodesList){
		.underlyingError = -1,
		.fsEventsError = 1,
	};
}

+ (RCIOFileManagerErrorMessagesList)errorMessages {
	return (RCIOFileManagerErrorMessagesList){
		@"a call to the underlying framework code failed, check NSUnderlyingErrorKey for details",
		@"failed to interface with the FSEvents API",
	};
}

#if !TARGET_OS_IPHONE
static void fsEventsCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
	void (^callbackBlock)(NSArray *) = (__bridge void (^)(NSArray *))(clientCallBackInfo);
	NSArray *paths = (__bridge NSArray *)(eventPaths);
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:paths.count];

	for (NSString *path in paths) {
		[urls addObject:[NSURL fileURLWithPath:path]];
	}

	callbackBlock(urls);
}

static const void *copyCallbackBlock(const void *block) {
	return _Block_copy(block);
}

static void releaseCallbackBlock(const void *block) {
	_Block_release(block);
}

+ (RACSignal *)changesAtURL:(NSURL *)url delayedUpTo:(NSTimeInterval)delay {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		void (^callbackBlock)(NSArray *) = ^(NSArray *urls){
			[subscriber sendNext:urls];
		};

		FSEventStreamContext context;
		context.version = 0;
		context.info = (__bridge void *)callbackBlock;
		context.retain = copyCallbackBlock;
		context.release = releaseCallbackBlock;
		context.copyDescription = NULL;

		FSEventStreamRef stream = FSEventStreamCreate(kCFAllocatorDefault, fsEventsCallback, &context, (__bridge CFArrayRef)(@[ url.path ]), kFSEventStreamEventIdSinceNow, delay, kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagWatchRoot);

		FSEventStreamScheduleWithRunLoop(stream, [NSRunLoop currentRunLoop].getCFRunLoop, kCFRunLoopDefaultMode);
		if (!FSEventStreamStart(stream)) {
			[subscriber sendError:[NSError errorWithDomain:self.errorDomain code:self.errorCodes.fsEventsError userInfo:@{ NSLocalizedDescriptionKey: self.errorMessages.fsEventsError }]];
		};

		return [RACDisposable disposableWithBlock:^{
			FSEventStreamStop(stream);
			FSEventStreamInvalidate(stream);
			FSEventStreamRelease(stream);
		}];
	}];
}
#else
+ (RACSignal *)changesAtURL:(NSURL *)url delayedUpTo:(NSTimeInterval)delay {
	return [[[changesBroadcastSubject filter:^(NSURL *affectedURL) {
		NSString *urlPath = url.URLByResolvingSymlinksInPath.path;
		NSString *affectedPathParent = affectedURL.URLByDeletingLastPathComponent.URLByResolvingSymlinksInPath.path;
		return (BOOL)([urlPath hasPrefix:affectedPathParent] || [affectedPathParent hasPrefix:urlPath]);
	}] bufferWithTime:delay onScheduler:RACScheduler.currentScheduler] map:^(RACTuple *tuple) {
		return tuple.allObjects;
	}];
}
#endif

+ (RACSignal *)contentsOfDirectoryAtURL:(NSURL *)url options:(NSDirectoryEnumerationOptions)options {
	return [RACSignal createSignal:^(id<RACSubscriber> outerSubscriber) {
		RACSignal *signal = [RACSignal createSignal:^(id<RACSubscriber> innerSubscriber) {
			NSDirectoryEnumerator *enumerator = [[[NSFileManager alloc] init] enumeratorAtURL:url includingPropertiesForKeys:nil options:options errorHandler:^BOOL(NSURL *errorURL, NSError *error) {
				if (errorURL == nil) {
					[innerSubscriber sendError:[NSError errorWithDomain:self.errorDomain code:self.errorCodes.underlyingError userInfo:@{ NSLocalizedDescriptionKey: self.errorMessages.underlyingError, NSUnderlyingErrorKey: error }]];
					return NO;
				}
				return YES;
			}];
			return [enumerator.rac_promise.deferred subscribe:innerSubscriber];
		}];

		RACDisposable *disposable = [[[self changesAtURL:url delayedUpTo:0.5] mapReplace:signal] subscribe:outerSubscriber];
		[outerSubscriber sendNext:signal];
		return disposable;
	}];
}

+ (RACSignal *)moveItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[[NSFileManager alloc] init] moveItemAtURL:sourceURL toURL:destinationURL error:&error];
		if (success) {
			broadcastChange(sourceURL);
			broadcastChange(destinationURL);
			[subscriber sendCompleted];
		} else {
			[subscriber sendError:[NSError errorWithDomain:self.errorDomain code:self.errorCodes.underlyingError userInfo:@{ NSLocalizedDescriptionKey: self.errorMessages.underlyingError, NSUnderlyingErrorKey: error }]];
		}
		return (RACDisposable *)nil;
	}];
}

+ (RACSignal *)copyItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[[NSFileManager alloc] init] copyItemAtURL:sourceURL toURL:destinationURL error:&error];
		if (success) {
			broadcastChange(destinationURL);
			[subscriber sendCompleted];
		} else {
			[subscriber sendError:[NSError errorWithDomain:self.errorDomain code:self.errorCodes.underlyingError userInfo:@{ NSLocalizedDescriptionKey: self.errorMessages.underlyingError, NSUnderlyingErrorKey: error }]];
		}
		return (RACDisposable *)nil;
	}];
}

+ (RACSignal *)removeItemAtURL:(NSURL *)url {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[[NSFileManager alloc] init] removeItemAtURL:url error:&error];
		if (success) {
			broadcastChange(url);
			[subscriber sendCompleted];
		} else {
			[subscriber sendError:[NSError errorWithDomain:self.errorDomain code:self.errorCodes.underlyingError userInfo:@{ NSLocalizedDescriptionKey: self.errorMessages.underlyingError, NSUnderlyingErrorKey: error }]];
		}
		return (RACDisposable *)nil;
	}];
}

@end
