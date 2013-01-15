//
//  RCIOItemExamples.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 14/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

NSString * const RCIOItemExamples = @"RCIOItemExamples";
NSString * const RCIOItemExampleClass = @"RCIOItemExampleClass";

SharedExampleGroupsBegin(RCIOItem)

sharedExamplesFor(RCIOItemExamples, ^(NSDictionary *data) {
	__block NSURL *itemURL = nil;
	__block RCIOItem *item = nil;
	__block BOOL (^itemExists)(void) = nil;
	
	before(^{
		itemURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", @(arc4random_uniform(8999999) + 1000000)]];
		itemExists = ^{
			return [NSFileManager.defaultManager fileExistsAtPath:itemURL.path];
		};
		
		[[data[RCIOItemExampleClass] itemWithURL:itemURL] subscribeNext:^(id x) {
			item = x;
		}];
		expect(item).willNot.beNil();
	});
	
	it(@"should be able to create itself", ^{
		expect(itemExists()).to.beFalsy();
		__block RCIOItem *createdItem = nil;
		__block BOOL errored = NO;
		__block BOOL completed = NO;
		
		[[item create] subscribeNext:^(id x) {
			createdItem = x;
		}error:^(NSError *error) {
			errored = YES;
		} completed:^{
			completed = YES;
		}];
		
		expect(createdItem).willNot.beNil();
		expect(errored).will.beFalsy();
		expect(completed).will.beTruthy();
		expect(itemExists()).will.beTruthy();
	});
	
	after(^{
		[NSFileManager.defaultManager removeItemAtURL:itemURL error:NULL];
	});
	

});

SharedExampleGroupsEnd
