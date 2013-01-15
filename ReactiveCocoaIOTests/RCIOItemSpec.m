//
//  RCIOItemSpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 15/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItemExamples.h"

SpecBegin(RCIOItem)

describe(@"RCIOItem", ^{
	__block NSURL *itemURL = nil;
	__block RCIOItem *item = nil;
	__block BOOL (^itemExists)(void) = nil;
	
	before(^{
		itemURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", @(arc4random_uniform(8999999) + 1000000)]];
		itemExists = ^{
			return [NSFileManager.defaultManager fileExistsAtPath:itemURL.path];
		};
	});
	
	after(^{
		item = nil;
		[NSFileManager.defaultManager removeItemAtURL:itemURL error:NULL];
		expect(itemExists()).will.beFalsy();
		itemURL = nil;
	});
	
	it(@"should not return an item that doesn't exist", ^{
		expect(itemExists()).to.beFalsy();
		__block BOOL errored = NO;
		__block BOOL completed = NO;
		
		[[RCIOItem itemWithURL:itemURL] subscribeNext:^(id x) {
			item = x;
		} error:^(NSError *error) {
			errored = YES;
		} completed:^{
			completed = YES;
		}];
		
		expect(item).will.beNil();
		expect(errored).will.beTruthy();
		expect(completed).will.beFalsy();
	});
	
	it(@"should return an item that does exist", ^{
		NSURL *existingItemURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
		expect([NSFileManager.defaultManager fileExistsAtPath:existingItemURL.path]).to.beTruthy();
		__block BOOL errored = NO;
		__block BOOL completed = NO;
		
		[[RCIOItem itemWithURL:existingItemURL] subscribeNext:^(id x) {
			item = x;
		} error:^(NSError *error) {
			errored = YES;
		} completed:^{
			completed = YES;
		}];
		
		expect(item).willNot.beNil();
		expect(errored).will.beFalsy();
		expect(completed).will.beTruthy();
	});
});

SpecEnd
