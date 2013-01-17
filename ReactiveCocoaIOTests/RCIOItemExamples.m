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
	__block NSURL * (^randomURL)(void) = nil;
	__block BOOL (^itemExists)(void) = nil;
	
	before(^{
		randomURL = ^{
			return [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", @(arc4random_uniform(8999999) + 1000000)]];
		};
		itemExists = ^{
			return [NSFileManager.defaultManager fileExistsAtPath:itemURL.path];
		};
		
		itemURL = randomURL();
		[[data[RCIOItemExampleClass] itemWithURL:itemURL] subscribeNext:^(id x) {
			item = x;
		}];
		
		expect(item).willNot.beNil();
		expect(itemExists()).will.beTruthy();
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
	
	it(@"should deallocate normally", ^{
		__block BOOL deallocd = NO;
		NSURL *url = randomURL();
		
		@autoreleasepool {
			__block BOOL disposableAttached = NO;
			[[data[RCIOItemExampleClass] itemWithURL:url] subscribeNext:^(id x) {
				[x rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
			} completed:^{
				disposableAttached = YES;
			}];
			expect(disposableAttached).will.beTruthy();
		}
		
		expect(deallocd).will.beTruthy();
		[NSFileManager.defaultManager removeItemAtURL:url error:NULL];
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
		__block BOOL gotParent = NO;
		__block BOOL errored = NO;
		
		[[[item parentSignal] take:1] subscribeNext:^(id x) {
			if (x != nil) gotParent = YES;
		}error:^(NSError *error) {
			errored = YES;
		}];
		
		expect(gotParent).will.beTruthy();
		expect(errored).will.beFalsy();
	});
	
	it(@"should let it's parent deallocate", ^{
		__block BOOL parentDeallocd = NO;
		
		@autoreleasepool {
			__block BOOL disposableAttached = NO;
			[[[item parentSignal] take:1] subscribeNext:^(RCIODirectory *parent) {
				[parent rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
					parentDeallocd = YES;
				}]];
			} completed:^{
				disposableAttached = YES;
			}];
			expect(disposableAttached).will.beTruthy();
		}
		
		expect(parentDeallocd).will.beTruthy();
	});
	
	//	it(@"should deallocate if a reference to it's parent is kept", ^{
	//		__block BOOL deallocd = NO;
	//		NSURL *url = randomURL();
	//		__block RCIODirectory *parent = nil;
	//
	//		@autoreleasepool {
	//			__block BOOL finishedGettingChildren = NO;
	//			[[data[RCIOItemExampleClass] itemWithURL:url] subscribeNext:^(RCIOItem *x) {
	//				[x rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
	//					deallocd = YES;
	//				}]];
	//				[[[x parentSignal] take:1] subscribeNext:^(RCIODirectory *y) {
	//					parent = y;
	//					[[[y childrenSignal] take:1] subscribeNext:^(NSArray *children) {
	//						expect(children.count).to.beGreaterThan(0);
	//						finishedGettingChildren = YES;
	//					}];
	//				}];
	//			}];
	//			expect(parent).willNot.beNil();
	//			expect(finishedGettingChildren).will.beTruthy();
	//		}
	//
	//		expect(deallocd).will.beTruthy();
	//		expect(parent).toNot.beNil();
	//		[NSFileManager.defaultManager removeItemAtURL:url error:NULL];
	//	});
	
	//	it(@"should be contained in it's parent's children", ^{
	//		__block RCIOItem *matchedItem = nil;
	//
	//		[[[[item parentSignal] take:1] flattenMap:^(RCIODirectory *parent) {
	//			return [[parent childrenSignal] take:1];
	//		}] subscribeNext:^(NSArray *children) {
	//			for (RCIOItem *child in children) {
	//				if (child == item) {
	//					matchedItem = child;
	//					break;
	//				}
	//			}
	//		}];
	//
	//		expect(matchedItem).will.beIdenticalTo(item);
	//	});
});

SharedExampleGroupsEnd
