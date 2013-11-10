//
//  RCIOFileManagerSpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import "RCIOTestUtilities.h"

SpecBegin(RCIOFileManager)

describe(@"RCIOFileManager", ^{
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

		it(@"should not let the directory react if the item is just renamed", ^{
			__block NSArray *receivedChildren = nil;
			[testRootDirectory.childrenSignal subscribeNext:^(NSArray *children) {
				receivedChildren = children;
			}];

			expect(receivedChildren).willNot.beNil();
			receivedChildren = nil;

			RCIOItem *renamedItem = [[item moveTo:nil withName:newName replaceExisting:NO] asynchronousFirstOrDefault:nil success:&success error:&error];

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(renamedItem).toNot.beNil();
			expect(receivedChildren).to.beNil();
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
});

SpecEnd
