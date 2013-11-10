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
	return RACSignal.empty;
}

+ (RACSignal *)moveItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL {
	return RACSignal.empty;
}

+ (RACSignal *)copyItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL {
	return RACSignal.empty;
}

+ (RACSignal *)removeItemAtURL:(NSURL *)url {
	return RACSignal.empty;
}

@end
