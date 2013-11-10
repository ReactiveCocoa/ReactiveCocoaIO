//
//  RCIOItemExamples.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 14/01/2013.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import "RCIOTestUtilities.h"

NSString * const RCIOItemExamples = @"RCIOItemExamples";
NSString * const RCIOItemExampleClass = @"RCIOItemExampleClass";
NSString * const RCIOItemExampleBlock = @"RCIOItemExampleBlock";

SharedExampleGroupsBegin(RCIOItem)

sharedExamplesFor(RCIOItemExamples, ^(NSDictionary *data) {	
	Class RCIOItemSubclass = data[RCIOItemExampleClass];
	void (^createItemAtURL)(NSURL *) = data[RCIOItemExampleBlock];
	
	__block NSURL *testRootDirectoryURL;
	__block NSURL *itemURL;
	__block RCIOItem *item;
	__block BOOL success;
	__block NSError *error;
	
	before(^{
		testRootDirectoryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:randomString()];
		itemURL = [testRootDirectoryURL URLByAppendingPathComponent:@"item"];
		item = nil;
		success = NO;
		error = nil;
		
		[[[NSFileManager alloc] init] createDirectoryAtURL:testRootDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
	});
	
	after(^{
		[[[NSFileManager alloc] init] removeItemAtURL:testRootDirectoryURL error:NULL];
	});
	
	describe(@"RCIOItem", ^{
		it(@"should not return an item that doesn't exist", ^{
			expect(itemExistsAtURL(itemURL)).to.beFalsy();
			
			item = [[RCIOItem itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).toNot.beNil();
			expect(success).to.beFalsy();
			expect(item).to.beNil();
		});
		
		it(@"should return an item that does exist", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			item = [[RCIOItem itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(item).toNot.beNil();
			expect(item.class).to.equal(RCIOItemSubclass);
		});
	});
	
	describe(@"base interface", ^{
		it(@"should create an item", ^{
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(item).toNot.beNil();
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
		});
		
		it(@"should load an item", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(item).toNot.beNil();
		});
		
		it(@"should not load an item if RCIOItemModeExclusiveAccess is specified", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			item = [[RCIOItemSubclass itemWithURL:itemURL mode:RCIOItemModeExclusiveAccess] asynchronousFirstOrDefault:nil success:&success error:&error];
			expect(error).toNot.beNil();
			expect(success).to.beFalsy();
			expect(item).to.beNil();
		});
		
		it(@"should not load an item if RCIOItemModeExclusiveAccess is specified even if it was loaded before", ^{
			createItemAtURL(itemURL);
			expect(itemExistsAtURL(itemURL)).to.beTruthy();
			
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];

			expect(item).toNot.beNil();
			
			item = [[RCIOItemSubclass itemWithURL:itemURL mode:RCIOItemModeExclusiveAccess] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).toNot.beNil();
			expect(success).to.beFalsy();
			expect(item).to.beNil();
		});
				
		describe(@"after being created", ^{
			before(^{
				item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
				expect(item).toNot.beNil();
			});
			
			it(@"should return it's parent", ^{
				RCIODirectory *parent = [item.parentSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(parent).toNot.beNil();
			});

			it(@"should be contained in it's parent's children", ^{
				RCIODirectory *parent = [item.parentSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(parent).toNot.beNil();
				
				NSArray *children = [parent.childrenSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(children).toNot.beNil();
				
				RCIOItem *matchedItem = nil;
				for (RCIOItem *child in children) {
					if (child == item) {
						matchedItem = child;
						break;
					}
				}
				
				expect(matchedItem).to.beIdenticalTo(item);
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
				RCIOItem *item __attribute__((objc_precise_lifetime)) = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
				[item.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];

				expect(error).to.beNil();
				expect(success).to.beTruthy();

				__block BOOL receivedInitialAttributeValue = NO;
				[[item extendedAttributeChannelForKey:attributeKey] subscribeNext:^(NSString *value) {
					if (!receivedInitialAttributeValue) {
						expect(value).to.beNil();
						receivedInitialAttributeValue = YES;
					} else {
						receivedAttribute = value;
						success = YES;
					}
				} error:^(NSError *receivedError) {
					error = receivedError;
					success = NO;
				} completed:^{
					success = YES;
				}];

				[[item extendedAttributeChannelForKey:attributeKey] sendNext:attributeValue];

				expect(error).will.beNil();
				expect(success).will.beTruthy();
				expect(receivedAttribute).will.equal(attributeValue);
			}
			
			expect(deallocd).will.beTruthy();
			receivedAttribute = nil;
			
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(item).toNot.beNil();
			
			receivedAttribute = [[item extendedAttributeChannelForKey:attributeKey] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(receivedAttribute).to.equal(attributeValue);
		});
	});
	
	describe(@"memory management", ^{
		it(@"should deallocate normally", ^{
			__block BOOL deallocd = NO;
			
			@autoreleasepool {
				RCIOItem *item __attribute__((objc_precise_lifetime)) = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
				[item.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
						deallocd = YES;
				}]];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
			}
			
			expect(deallocd).will.beTruthy();
		});
		
		it(@"should deallocate even if an extended attribute interface has been created", ^{
			__block BOOL deallocd = NO;
			
			@autoreleasepool {
				RCIOItem *item __attribute__((objc_precise_lifetime)) = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
				RACChannelTerminal *attributeSubject __attribute__((unused, objc_precise_lifetime)) = [item extendedAttributeChannelForKey:@"key"];
				[item.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
			}
			
			expect(deallocd).will.beTruthy();
		});
		
		it(@"should let it's parent deallocate", ^{
			__block BOOL parentDeallocd = NO;
			
			@autoreleasepool {
				RCIOItem *item __attribute__((objc_precise_lifetime)) = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				
				RCIODirectory *parent __attribute__((objc_precise_lifetime)) = [item.parentSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				[parent.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					parentDeallocd = YES;
				}]];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
			}
			
			expect(parentDeallocd).will.beTruthy();
		});
		
		it(@"should deallocate if a reference to it's parent is kept after getting the parent's children", ^{
			__block BOOL deallocd = NO;
			__block RCIODirectory *parent = nil;
			__block BOOL childrenDeallocd = NO;
			
			@autoreleasepool {
				RCIOItem *item __attribute__((objc_precise_lifetime)) = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
				[item.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				
				parent = [item.parentSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				
				NSArray *children __attribute__((objc_precise_lifetime)) = [parent.childrenSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				[children.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					childrenDeallocd = YES;
				}]];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
			}
			
			expect(parent).toNot.beNil();
			expect(childrenDeallocd).will.beTruthy();
			expect(deallocd).will.beTruthy();
		});
	});
	
	describe(@"uniquing", ^{
		before(^{
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];			
			expect(item).toNot.beNil();
		});
		
		it(@"should be uniqued", ^{
			RCIOItem *sameItem = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(sameItem).to.beIdenticalTo(item);
		});
		
		it(@"should unique it's parent", ^{
			RCIODirectory *parent1 = [[RCIODirectory itemWithURL:item.url.URLByDeletingLastPathComponent] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(parent1).toNot.beNil();
			
			RCIODirectory *parent2 = [item.parentSignal asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(parent2).to.beIdenticalTo(parent1);
		});
	});
});

SharedExampleGroupsEnd
