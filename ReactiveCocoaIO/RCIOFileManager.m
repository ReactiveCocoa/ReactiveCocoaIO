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
		[outerSubscriber sendNext:signal];
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
