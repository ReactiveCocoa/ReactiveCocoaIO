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
	
	after(^{
		item = nil;
		[NSFileManager.defaultManager removeItemAtURL:itemURL error:NULL];
		expect(itemExists()).will.beFalsy();
		itemURL = nil;
	});
	
	it(@"should be uniqued", ^{
		__block RCIOItem *sameItem = nil;
		
		[[data[RCIOItemExampleClass] itemWithURL:itemURL] subscribeNext:^(id x) {
			sameItem = x;
		}];
		
		expect(sameItem).will.beIdenticalTo(item);
	});
	
	describe(@"before being created", ^{
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
			
			expect(createdItem).will.equal(item);
			expect(errored).will.beFalsy();
			expect(completed).will.beTruthy();
			expect(itemExists()).will.beTruthy();
		});
	});
		
	describe(@"after being created", ^{
		before(^{
			expect(itemExists()).to.beFalsy();
			__block RCIOItem *createdItem = nil;
			[[item create] subscribeNext:^(id x) {
				createdItem = x;
			}];
			expect(createdItem).will.equal(item);
			expect(itemExists()).will.beTruthy();
		});
		
		it(@"should be able to delete itself", ^{
			__block RCIOItem *deletedItem = nil;
			__block BOOL errored = NO;
			__block BOOL completed = NO;
			
			[[item delete] subscribeNext:^(id x) {
				deletedItem = x;
			} error:^(NSError *error) {
				errored = NO;
			} completed:^{
				completed = YES;
			}];

			expect(deletedItem).will.equal(item);
			expect(errored).will.beFalsy();
			expect(completed).will.beTruthy();
			expect(itemExists()).will.beFalsy();
		});

		it(@"should have a parent", ^{
			__block RCIODirectory *parent = nil;
			__block BOOL errored = NO;
			
			[[item parentSignal] subscribeNext:^(id x) {
				parent = x;
			}error:^(NSError *error) {
				errored = YES;
			}];
			
			expect(parent).willNot.beNil();
			expect(errored).will.beFalsy();
		});
		
		it(@"should be contained in it's parent's children", ^{
			__block RCIOItem *matchedItem = nil;
			
			[[[[item parentSignal] take:1] flattenMap:^(RCIODirectory *parent) {
				return [[parent childrenSignal] take:1];
			}] subscribeNext:^(NSArray *children) {
				for (RCIOItem *child in children) {
					if (child == item) {
						matchedItem = child;
						break;
					}
				}
			}];
			
			expect(matchedItem).will.beIdenticalTo(item);
		});
	});
});

SharedExampleGroupsEnd
