//
//  RCIOItemExamples.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 14/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

NSString * const RCIOItemExamples = @"RCIOItemExamples";
NSString * const RCIOItemExampleClass = @"RCIOItemExampleClass";
NSString * const RCIOItemExampleBlock = @"RCIOItemExampleBlock";

static NSString *randomString() {
	return [NSString stringWithFormat:@"%@", @(arc4random_uniform(8999999) + 1000000)];
};

static BOOL itemExistsAtURL(NSURL *url) {
	return [NSFileManager.defaultManager fileExistsAtPath:url.path];
}

SharedExampleGroupsBegin(RCIOItem)

sharedExamplesFor(RCIOItemExamples, ^(NSDictionary *data) {
	
	__block NSURL *testRootDirectory = nil;
	Class RCIOItemSubclass = data[RCIOItemExampleClass];
	void (^createItemAtURL)(NSURL *) = data[RCIOItemExampleBlock];
	
	before(^{
		testRootDirectory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:randomString()];
		[NSFileManager.defaultManager createDirectoryAtURL:testRootDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
	});
	
	after(^{
		[NSFileManager.defaultManager removeItemAtURL:testRootDirectory error:NULL];
	});
	
	describe(@"base interface", ^{
		it(@"should create an item", ^{
			NSURL *url = [testRootDirectory URLByAppendingPathComponent:@"test"];
			__block RCIOItem *item = nil;
			__block BOOL errored = NO;
			__block BOOL completed = NO;
			
			[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = NO;
			} completed:^{
				completed = YES;
			}];
			
			expect(item).willNot.beNil();
			expect(errored).will.beFalsy();
			expect(completed).will.beTruthy();
			expect(itemExistsAtURL(url)).to.beTruthy();
		});
		
		it(@"should load an item", ^{
			NSURL *url = [testRootDirectory URLByAppendingPathComponent:@"test"];
			__block RCIOItem *item = nil;
			__block BOOL errored = NO;
			__block BOOL completed = NO;
			
			createItemAtURL(url);
			expect(itemExistsAtURL(url)).to.beTruthy();
			
			[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = NO;
			} completed:^{
				completed = YES;
			}];
			
			expect(item).willNot.beNil();
			expect(errored).will.beFalsy();
			expect(completed).will.beTruthy();
		});
		
		it(@"should delete an item", ^{
			NSURL *url = [testRootDirectory URLByAppendingPathComponent:@"test"];
			__block RCIOItem *item = nil;
			__block RCIOItem *deletedItem = nil;
			__block BOOL errored = NO;
			__block BOOL completed = NO;
			
			createItemAtURL(url);
			[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(id x) {
				item = x;
			}];
			
			expect(item).willNot.beNil();
			
			[[item delete] subscribeNext:^(id x) {
				deletedItem = x;
			} error:^(NSError *error) {
				errored = NO;
			} completed:^{
				completed = YES;
			}];
			
			expect(deletedItem).will.beIdenticalTo(item);
			expect(errored).will.beFalsy();
			expect(completed).will.beTruthy();
			expect(itemExistsAtURL(url)).will.beFalsy();
		});
	});
	
	describe(@"memory management", ^{
		it(@"should deallocate normally", ^{
			__block BOOL deallocd = NO;
			NSURL *url = [testRootDirectory URLByAppendingPathComponent:@"test"];
			
			@autoreleasepool {
				__block BOOL disposableAttached = NO;
				[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(id x) {
					[x rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
						deallocd = YES;
					}]];
				} completed:^{
					disposableAttached = YES;
				}];
				expect(disposableAttached).will.beTruthy();
			}
			
			expect(deallocd).will.beTruthy();
		});
		
	});
	
	describe(@"uniquing", ^{
		it(@"should be uniqued", ^{
			NSURL *url = [testRootDirectory URLByAppendingPathComponent:@"test"];
			__block RCIOItem *item = nil;
			__block RCIOItem *sameItem = nil;
			
			[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(id x) {
				item = x;
			}];
			
			expect(item).willNot.beNil();
			
			[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(id x) {
				sameItem = x;
			}];
			
			expect(sameItem).will.beIdenticalTo(item);
		});
	});
	
//	it(@"should return it's parent", ^{
//		__block RCIODirectory *sentParent = nil;
//		__block BOOL errored = NO;
//		
//		[[[item parentSignal] take:1] subscribeNext:^(id x) {
//			sentParent = x;
//		}error:^(NSError *error) {
//			errored = YES;
//		}];
//		
//		expect(sentParent).will.equal(parent);
//		expect(errored).will.beFalsy();
//	});
//	
//	it(@"should let it's parent deallocate", ^{
//		__block BOOL parentDeallocd = NO;
//		
//		@autoreleasepool {
//			__block BOOL disposableAttached = NO;
//			[[[item parentSignal] take:1] subscribeNext:^(RCIODirectory *parent) {
//				[parent rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
//					parentDeallocd = YES;
//				}]];
//			} completed:^{
//				disposableAttached = YES;
//			}];
//			expect(disposableAttached).will.beTruthy();
//		}
//		
//		expect(parentDeallocd).will.beTruthy();
//	});
//	
//	it(@"should deallocate if a reference to it's parent is kept", ^{
//		__block BOOL deallocd = NO;
//		NSURL *url = randomURL();
//		__block RCIODirectory *parent = nil;
//
//		@autoreleasepool {
//			__block BOOL finishedGettingChildren = NO;
//			[[RCIOItemSubclass itemWithURL:url] subscribeNext:^(RCIOItem *x) {
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
//
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
