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
	Class RCIOItemSubclass = data[RCIOItemExampleClass];
	void (^createItemAtURL)(NSURL *) = data[RCIOItemExampleBlock];
	
	__block NSURL *testRootDirectory;
	__block NSURL *itemURL;
	__block RCIOItem *item;
	__block BOOL errored;
	__block BOOL completed;
	
	before(^{
		testRootDirectory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:randomString()];
		itemURL = [testRootDirectory URLByAppendingPathComponent:@"test"];
		item = nil;
		errored = NO;
		completed = NO;
		
		[NSFileManager.defaultManager createDirectoryAtURL:testRootDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
	});
	
	after(^{
		expect(errored).to.beFalsy();
		
		[NSFileManager.defaultManager removeItemAtURL:testRootDirectory error:NULL];
	});
	
	describe(@"RCIOItem", ^{
		it(@"should not return an item that doesn't exist", ^{
			expect(itemExistsAtURL(itemURL)).to.beFalsy();
			
			[[RCIOItem itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = YES;
			}];
			
			expect(errored).will.beTruthy();
			// Reset error before the after block
			errored = NO;
			expect(item).will.beNil();
		});
		
		it(@"should return an item that does exist", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			[[RCIOItem itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = YES;
			} completed:^{
				completed = YES;
			}];
			
			expect(item).willNot.beNil();
			expect(item.class).to.equal(RCIOItemSubclass);
			expect(completed).will.beTruthy();
		});
	});
	
	describe(@"base interface", ^{
		it(@"should create an item", ^{			
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = YES;
			} completed:^{
				completed = YES;
			}];
			
			expect(item).willNot.beNil();
			expect(completed).will.beTruthy();
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
		});
		
		it(@"should load an item", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = YES;
			} completed:^{
				completed = YES;
			}];
			
			expect(item).willNot.beNil();
			expect(completed).will.beTruthy();
		});
		
		it(@"should not load an item if RCIOItemModeExclusiveAccess is specified", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			[[RCIOItemSubclass itemWithURL:itemURL mode:RCIOItemModeExclusiveAccess] subscribeNext:^(id x) {
				item = x;
			} error:^(NSError *error) {
				errored = YES;
			}];
			
			expect(errored).will.beTruthy();
			// Reset error before the after block
			errored = NO;
			expect(item).will.beNil();
		});
		
		it(@"should not load an item if RCIOItemModeExclusiveAccess is specified even if it was loaded before", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			}];
			
			expect(item).willNot.beNil();
			
			__block RCIOItem *item2 = nil;
			
			[[RCIOItemSubclass itemWithURL:itemURL mode:RCIOItemModeExclusiveAccess] subscribeNext:^(id x) {
				item2 = x;
			} error:^(NSError *error) {
				errored = YES;
			}];
			
			expect(errored).will.beTruthy();
			// Reset error before the after block
			errored = NO;
			expect(item2).will.beNil();
		});
		
		it(@"should delete an item", ^{
			__block RCIOItem *deletedItem = nil;
			
			createItemAtURL(itemURL);
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			}];
			
			expect(item).willNot.beNil();
			
			[[item delete] subscribeNext:^(id x) {
				deletedItem = x;
			} error:^(NSError *error) {
				errored = YES;
			} completed:^{
				completed = YES;
			}];
			
			expect(deletedItem).will.beIdenticalTo(item);
			expect(completed).will.beTruthy();
			expect(itemExistsAtURL(itemURL)).will.beFalsy();
		});
		
		describe(@"after being created", ^{
			
			before(^{
				[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
					item = x;
				}];
				
				expect(item).willNot.beNil();
			});
			
			it(@"should return it's parent", ^{
				__block RCIODirectory *parent = nil;
				
				[[[item parentSignal] take:1] subscribeNext:^(id x) {
					parent = x;
				}error:^(NSError *error) {
					errored = YES;
				}];
				
				expect(parent).willNot.beNil();
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
	
	describe(@"extended attributes", ^{
		it(@"should save and load extended attributes", ^{
			__block BOOL deallocd = NO;
			NSString *attributeKey = @"key";
			NSString *attributeValue = @"value";
			__block NSString *receivedAttribute = nil;
			
			@autoreleasepool {
				// Keep a reference to item or it'll deallocate before the attribute value is received
				__block RCIOItem *item __attribute__((objc_precise_lifetime)) = nil;
				[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x __attribute__((objc_precise_lifetime))) {
					item = x;
					[x rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
						deallocd = YES;
					}]];
					RACPropertySubject *attributeSubject __attribute__((objc_precise_lifetime)) = [x extendedAttributeSubjectForKey:attributeKey];
					[attributeSubject subscribeNext:^(id x) {
						receivedAttribute = x;
					}];
					[attributeSubject sendNext:attributeValue];
				}];
				expect(receivedAttribute).will.equal(attributeValue);
			}
			
			expect(deallocd).will.beTruthy();
			receivedAttribute = nil;
			
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				[[x extendedAttributeSubjectForKey:attributeKey] subscribeNext:^(id x) {
					receivedAttribute = x;
				}];
			}];
			
			expect(receivedAttribute).will.equal(attributeValue);
		});
	});
	
	describe(@"memory management", ^{
		it(@"should deallocate normally", ^{
			__block BOOL deallocd = NO;
			
			@autoreleasepool {
				__block BOOL disposableAttached = NO;
				[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x __attribute__((objc_precise_lifetime))) {
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
		
		it(@"should deallocate even if an extended attribute interface has been created", ^{
			__block BOOL deallocd = NO;
			
			@autoreleasepool {
				__block BOOL disposableAttached = NO;
				[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x __attribute__((objc_precise_lifetime))) {
					RACPropertySubject *attributeSubject __attribute__((unused, objc_precise_lifetime)) = [x extendedAttributeSubjectForKey:@"key"];
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
		
		it(@"should let it's parent deallocate", ^{
			__block BOOL parentDeallocd = NO;
			
			@autoreleasepool {
				__block BOOL disposableAttached = NO;
				[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(RCIOItem *item) {
					[[[item parentSignal] take:1] subscribeNext:^(RCIODirectory *parent __attribute__((objc_precise_lifetime))) {
						[parent rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
							parentDeallocd = YES;
						}]];
					} completed:^{
						disposableAttached = YES;
					}];
				}];
				expect(disposableAttached).will.beTruthy();
			}
			
			expect(parentDeallocd).will.beTruthy();
		});
		
		it(@"should deallocate if a reference to it's parent is kept after getting the parent's children", ^{
			__block BOOL deallocd = NO;
			__block RCIODirectory *parent = nil;
			
			@autoreleasepool {
				__block BOOL finishedGettingChildren = NO;
				[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(RCIOItem *x __attribute__((objc_precise_lifetime))) {
					[x rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
						deallocd = YES;
					}]];
					[[[x parentSignal] take:1] subscribeNext:^(RCIODirectory *y) {
						parent = y;
						[[[y childrenSignal] take:1] subscribeNext:^(NSArray *children __attribute__((objc_precise_lifetime))) {
							expect(children.count).to.beGreaterThan(0);
							finishedGettingChildren = YES;
						}];
					}];
				}];
				expect(parent).willNot.beNil();
				expect(finishedGettingChildren).will.beTruthy();
			}
			
			expect(deallocd).will.beTruthy();
			expect(parent).toNot.beNil();
		});
	});
	
	describe(@"uniquing", ^{
		before(^{
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				item = x;
			}];
			
			expect(item).willNot.beNil();
		});
		
		it(@"should be uniqued", ^{
			__block RCIOItem *sameItem = nil;
			
			[[RCIOItemSubclass itemWithURL:itemURL] subscribeNext:^(id x) {
				sameItem = x;
			}];
			
			expect(sameItem).will.beIdenticalTo(item);
		});
		
		it(@"should unique it's parent", ^{
			__block RCIODirectory *parent1 = nil;
			__block RCIODirectory *parent2 = nil;
			
			[[RCIODirectory itemWithURL:[item.url URLByDeletingLastPathComponent]] subscribeNext:^(id x) {
				parent1 = x;
			}];
			
			expect(parent1).willNot.beNil();
			
			[[[item parentSignal] take:1] subscribeNext:^(id x) {
				parent2 = x;
			}];
			
			expect(parent2).will.beIdenticalTo(parent1);
		});
	});
});

SharedExampleGroupsEnd
