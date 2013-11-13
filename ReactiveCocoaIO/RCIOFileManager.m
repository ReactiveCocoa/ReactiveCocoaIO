//
//  RCIOFileManager.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import "RCIOFileManager.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

static void fsEventsCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
	void (^callbackBlock)(void) = (__bridge void (^)(void))(clientCallBackInfo);
	callbackBlock();
}

static const void *copyCallbackBlock(const void *block) {
	return _Block_copy(block);
}

static void releaseCallbackBlock(const void *block) {
	_Block_release(block);
}

@implementation RCIOFileManager

+ (RACSignal *)contentsOfDirectoryAtURL:(NSURL *)url options:(NSDirectoryEnumerationOptions)options {
	return [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> outerSubscriber) {
		RACSignal *signal = [RACSignal createSignal:^(id<RACSubscriber> innerSubscriber) {
			NSDirectoryEnumerator *enumerator = [[[NSFileManager alloc] init] enumeratorAtURL:url includingPropertiesForKeys:nil options:options errorHandler:^BOOL(NSURL *errorURL, NSError *error) {
				if (errorURL == nil) {
					[innerSubscriber sendError:error];
					return NO;
				}
				return YES;
			}];
			return [enumerator.rac_promise.deferred subscribe:innerSubscriber];
		}];

		void (^callbackBlock)(void) = ^{
			[outerSubscriber sendNext:signal];
		};

		FSEventStreamContext context;
		context.version = 0;
		context.info = (__bridge void *)callbackBlock;
		context.retain = copyCallbackBlock;
		context.release = releaseCallbackBlock;
		context.copyDescription = NULL;

		FSEventStreamRef stream = FSEventStreamCreate(kCFAllocatorDefault, fsEventsCallback, &context, (__bridge CFArrayRef)(@[ url.path ]), kFSEventStreamEventIdSinceNow, 3.0,  kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagWatchRoot);

		FSEventStreamScheduleWithRunLoop(stream, [NSRunLoop currentRunLoop].getCFRunLoop, kCFRunLoopDefaultMode);
		FSEventStreamStart(stream);

		[outerSubscriber sendNext:signal];

		return [RACDisposable disposableWithBlock:^{
			FSEventStreamStop(stream);
			FSEventStreamInvalidate(stream);
			FSEventStreamRelease(stream);
		}];
	}];
}

+ (RACSignal *)moveItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL {
	return [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[[NSFileManager alloc] init] moveItemAtURL:sourceURL toURL:destinationURL error:&error];
		if (success) {
			[subscriber sendCompleted];
		} else {
			[subscriber sendError:error];
		}
		return nil;
	}];
}

+ (RACSignal *)copyItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL {
	return [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[[NSFileManager alloc] init] copyItemAtURL:sourceURL toURL:destinationURL error:&error];
		if (success) {
			[subscriber sendCompleted];
		} else {
			[subscriber sendError:error];
		}
		return nil;
	}];
}

+ (RACSignal *)removeItemAtURL:(NSURL *)url {
	return [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[[NSFileManager alloc] init] removeItemAtURL:url error:&error];
		if (success) {
			[subscriber sendCompleted];
		} else {
			[subscriber sendError:error];
		}
		return nil;
	}];
}

@end
