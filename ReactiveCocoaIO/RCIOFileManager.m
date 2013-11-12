//
//  RCIOFileManager.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import "RCIOFileManager.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation RCIOFileManager

+ (RACSignal *)contentsOfDirectoryAtURL:(NSURL *)url options:(NSDirectoryEnumerationOptions)options {
	return [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
		NSDirectoryEnumerator *enumerator = [[[NSFileManager alloc] init] enumeratorAtURL:url includingPropertiesForKeys:nil options:options errorHandler:nil];

		[subscriber sendNext:enumerator.rac_promise.deferred];

		return nil;
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
