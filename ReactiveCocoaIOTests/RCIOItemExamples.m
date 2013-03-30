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
		
		[NSFileManager.defaultManager createDirectoryAtURL:testRootDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
	});
	
	after(^{
		[NSFileManager.defaultManager removeItemAtURL:testRootDirectoryURL error:NULL];
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
	
	describe(@"file management", ^{
		__block NSURL *directoryURL = nil;
		__block RCIODirectory *directory = nil;
		__block RCIOItem *receivedItem = nil;
		
		before(^{
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
			expect(item).toNot.beNil();
			
			directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
			directory = [[RCIODirectory itemWithURL:directoryURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
			expect(directory).toNot.beNil();
		});
		
		after(^{
			directoryURL = nil;
			directory = nil;
			receivedItem = nil;
		});
		
		describe(@"moving", ^{
			it(@"should move an item to a different directory with a different name", ^{
				NSString *newName = @"newName";
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:newName];
				
				receivedItem = [[item moveTo:directory withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).to.beIdenticalTo(item);
				expect(item.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
			
			it(@"should move an item even if the returned signal is not subscribed to", ^{
				NSString *newName = @"newName";
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:newName];
				
				[item moveTo:directory withName:newName replaceExisting:NO];
				
				expect(itemExistsAtURL(newItemURL)).will.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(item.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
			});
			
			it(@"should move an item to a different directory", ^{
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
				
				receivedItem = [[item moveTo:directory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).to.beIdenticalTo(item);
				expect(item.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
			
			it(@"should rename an item", ^{
				NSString *newName = @"newName";
				NSURL *newItemURL = [testRootDirectoryURL URLByAppendingPathComponent:newName];
				
				receivedItem = [[item moveTo:nil withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).to.beIdenticalTo(item);
				expect(item.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
			
			it(@"should not overwrite an item if not asked to", ^{
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
				createItemAtURL(newItemURL);
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
				
				receivedItem = [[item moveTo:directory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).toNot.beNil();
				expect(success).to.beFalsy();
				expect(receivedItem).to.beNil();
				expect(item.url).to.equal(itemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
			});

			it(@"should overwrite an item if asked to", ^{
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
				createItemAtURL(newItemURL);
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
				
				receivedItem = [[item moveTo:directory withName:nil replaceExisting:YES] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).to.beIdenticalTo(item);
				expect(item.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
		});
		
		describe(@"copying", ^{
			it(@"should copy an item to a different directory with a different name", ^{
				NSString *newName = @"newName";
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:newName];
				
				receivedItem = [[item copyTo:directory withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).toNot.beIdenticalTo(item);
				expect(receivedItem.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(item.url).to.equal(itemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
			
			it(@"should copy an item even if the returned signal is not subscribed to", ^{
				NSString *newName = @"newName";
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:newName];
				
				[item copyTo:directory withName:newName replaceExisting:NO];
				
				expect(itemExistsAtURL(newItemURL)).will.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
			});
			
			it(@"should copy an item to a different directory", ^{
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
				
				receivedItem = [[item copyTo:directory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).toNot.beIdenticalTo(item);
				expect(receivedItem.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(item.url).to.equal(itemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
			
			it(@"should copy an item with a different name", ^{
				NSString *newName = @"newName";
				NSURL *newItemURL = [testRootDirectoryURL URLByAppendingPathComponent:newName];
				
				receivedItem = [[item copyTo:nil withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).toNot.beIdenticalTo(item);
				expect(receivedItem.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(item.url).to.equal(itemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
			
			it(@"should not overwrite an item if not asked to", ^{
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
				createItemAtURL(newItemURL);
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
				
				receivedItem = [[item copyTo:directory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).toNot.beNil();
				expect(success).to.beFalsy();
				expect(receivedItem).to.beNil();
				expect(item.url).to.equal(itemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
			});
			
			it(@"should overwrite an item if asked to", ^{
				NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
				createItemAtURL(newItemURL);
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
				
				receivedItem = [[item copyTo:directory withName:nil replaceExisting:YES] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedItem).toNot.beIdenticalTo(item);
				expect(receivedItem.url).to.equal(newItemURL.URLByResolvingSymlinksInPath);
				expect(item.url).to.equal(itemURL.URLByResolvingSymlinksInPath);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
		});
		
		it(@"should delete an item", ^{
			__block RCIOItem *deletedItem = nil;
			
			createItemAtURL(itemURL);
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(item).toNot.beNil();
			
			deletedItem = [[item delete] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(deletedItem).to.beIdenticalTo(item);
			expect(item.url).to.beNil();
			expect(itemExistsAtURL(itemURL)).to.beFalsy();
		});
		
		it(@"should delete an item even if the returned signal is not subscribed to", ^{
			createItemAtURL(itemURL);
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(item).toNot.beNil();
			
			[item delete];
			
			expect(itemExistsAtURL(itemURL)).will.beFalsy();
			expect(item.url).to.beNil();
		});
	});
	
	describe(@"reactions", ^{
		NSString *newName = @"newName";
		
		__block NSURL *directoryURL;
		__block RCIODirectory *directory;
		__block NSArray *directoryChildrenURLs;
		__block RACDisposable *directoryChildrenDisposable;
		
		__block RCIODirectory *testRootDirectory;
		
		__block NSURL *overwriteTargetURL = nil;
		__block RCIOItem *overwriteTarget = nil;
		
		before(^{
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
			expect(item).toNot.beNil();
			
			directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
			directory = [[RCIODirectory itemWithURL:directoryURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
			expect(directory).toNot.beNil();
			
			directoryChildrenDisposable = [directory.childrenSignal subscribeNext:^(NSArray *children) {
				NSMutableArray *childrenURLs = [NSMutableArray array];
				for (RCIOItem *child in children) {
					[childrenURLs addObject:child.url];
				}
				directoryChildrenURLs = childrenURLs;
			}];
			
			testRootDirectory = [[RCIODirectory itemWithURL:testRootDirectoryURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
			expect(testRootDirectory).toNot.beNil();
			
			overwriteTargetURL = [directoryURL URLByAppendingPathComponent:itemURL.lastPathComponent];
			overwriteTarget = [[RCIOItemSubclass itemWithURL:overwriteTargetURL] asynchronousFirstOrDefault:nil success:NULL error:NULL];
			expect(overwriteTarget).toNot.beNil();
		});
		
		after(^{
			directoryURL = nil;
			directory = nil;
			directoryChildrenURLs = nil;
			[directoryChildrenDisposable dispose];
			directoryChildrenDisposable = nil;
			
			testRootDirectory = nil;
			
			overwriteTargetURL = nil;
			overwriteTarget = nil;
		});
		
		it(@"should let it's parent react to it's creation", ^{
			NSURL *newItemURL = [directoryURL URLByAppendingPathComponent:newName];
			RCIOItem *newItem = [[RCIOItemSubclass itemWithURL:newItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(newItem).toNot.beNil();
			expect(directoryChildrenURLs).to.equal((@[ overwriteTargetURL.URLByResolvingSymlinksInPath, newItemURL.URLByResolvingSymlinksInPath ]));
		});
		
		it(@"should let the destination directory of a move react", ^{
			NSURL *movedItemURL = [directoryURL URLByAppendingPathComponent:newName];
			RCIOItem *movedItem = [[item moveTo:directory withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(movedItem).toNot.beNil();
			expect(directoryChildrenURLs).to.equal((@[ overwriteTargetURL.URLByResolvingSymlinksInPath, movedItemURL.URLByResolvingSymlinksInPath ]));
		});
		
		it(@"should let the source directory of a move react", ^{
			RCIOItem *movedItem = [[overwriteTarget moveTo:testRootDirectory withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(movedItem).toNot.beNil();
			expect(directoryChildrenURLs).to.equal(@[]);
		});
		
		it(@"should let the destination directory of a copy react", ^{
			NSURL *copiedItemURL = [directoryURL URLByAppendingPathComponent:newName];
			RCIOItem *copiedItem = [[item copyTo:directory withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(copiedItem).toNot.beNil();
			expect(directoryChildrenURLs).to.equal((@[ overwriteTargetURL.URLByResolvingSymlinksInPath, copiedItemURL.URLByResolvingSymlinksInPath ]));
		});
		
		it(@"should not let the source directory of a copy react", ^{
			RCIOItem *copiedItem = [[overwriteTarget copyTo:testRootDirectory withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(copiedItem).toNot.beNil();
			expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
		});
		
		describe(@"on collisions", ^{
			describe(@"when not overwriting", ^{
				it(@"should not let the destination directory of a move react", ^{
					[[item moveTo:directory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.notTo.beNil();
					expect(success).to.beFalsy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
				
				it(@"should not let the source directory of a move react", ^{
					[[overwriteTarget moveTo:testRootDirectory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.notTo.beNil();
					expect(success).to.beFalsy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
				
				it(@"should not let the destination directory of a copy react", ^{
					[[item copyTo:directory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.notTo.beNil();
					expect(success).to.beFalsy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
				
				it(@"should not let the source directory of a copy react", ^{
					[[overwriteTarget copyTo:testRootDirectory withName:nil replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.notTo.beNil();
					expect(success).to.beFalsy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
			});
			
			describe(@"when overwriting", ^{
				it(@"should let the destination directory of a move react", ^{
					[[item moveTo:directory withName:nil replaceExisting:YES] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.beNil();
					expect(success).to.beTruthy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
				
				it(@"should let the source directory of a move react", ^{
					[[overwriteTarget moveTo:testRootDirectory withName:nil replaceExisting:YES] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.beNil();
					expect(success).to.beTruthy();
					expect(directoryChildrenURLs).to.equal(@[]);
				});
				
				it(@"should let the destination directory of a copy react", ^{
					[[item copyTo:directory withName:nil replaceExisting:YES] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.beNil();
					expect(success).to.beTruthy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
				
				it(@"should not let the source directory of a copy react", ^{
					[[overwriteTarget copyTo:testRootDirectory withName:nil replaceExisting:YES] asynchronousFirstOrDefault:nil success:&success error:&error];
					
					expect(error).to.beNil();
					expect(success).to.beTruthy();
					expect(directoryChildrenURLs).to.equal(@[ overwriteTargetURL.URLByResolvingSymlinksInPath ]);
				});
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
				[item rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];

				expect(error).to.beNil();
				expect(success).to.beTruthy();

				[[item extendedAttributeSubjectForKey:attributeKey] sendNext:attributeValue];
				receivedAttribute = [[item extendedAttributeSubjectForKey:attributeKey] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(receivedAttribute).to.equal(attributeValue);
			}
			
			expect(deallocd).will.beTruthy();
			receivedAttribute = nil;
			
			item = [[RCIOItemSubclass itemWithURL:itemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
			
			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(item).toNot.beNil();
			
			receivedAttribute = [[item extendedAttributeSubjectForKey:attributeKey] asynchronousFirstOrDefault:nil success:&success error:&error];
			
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
				[item rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
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
				RACPropertySubject *attributeSubject __attribute__((unused, objc_precise_lifetime)) = [item extendedAttributeSubjectForKey:@"key"];
				[item rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
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
				[parent rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
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
				[item rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				
				parent = [item.parentSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).to.beNil();
				expect(success).to.beTruthy();
				
				NSArray *children __attribute__((objc_precise_lifetime)) = [parent.childrenSignal asynchronousFirstOrDefault:nil success:&success error:&error];
				[children rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
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
