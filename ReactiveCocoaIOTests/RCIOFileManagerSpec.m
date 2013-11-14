//
//  RCIOFileManagerSpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "RCIOFileManager.h"
#import "RCIOTestUtilities.h"

static NSString * const RCIOFileManagerSharedExamplesName = @"RCIOFileManagerSharedExamplesName";
static NSString * const RCIOFileManagerSharedExamplesCreateBlock = @"RCIOFileManagerSharedExamplesCreateBlock";

static NSString * const RCIOFileManagerSharedReactionExamples = @"RCIOFileManagerSharedReactionExamples";
static NSString * const RCIOFileManagerSharedReactionExamplesTestRootDirectoryURL = @"RCIOFileManagerSharedReactionExamplesTestRootDirectoryURL";
static NSString * const RCIOFileManagerSharedReactionExamplesCreateBlock = @"RCIOFileManagerSharedReactionExamplesCreateBlock";
static NSString * const RCIOFileManagerSharedReactionExamplesMoveBlock = @"RCIOFileManagerSharedReactionExamplesMoveBlock";
static NSString * const RCIOFileManagerSharedReactionExamplesCopyBlock = @"RCIOFileManagerSharedReactionExamplesCopyBlock";
static NSString * const RCIOFileManagerSharedReactionExamplesRemoveBlock = @"RCIOFileManagerSharedReactionExamplesRemoveBlock";

SharedExampleGroupsBegin(RCIOFileManager)

sharedExamplesFor(RCIOFileManagerSharedReactionExamples, ^(NSDictionary *data) {
	__block NSURL *testRootDirectoryURL;
	__block void(^createFilesystemItem)(NSURL *);
	__block void(^moveFilesystemItem)(NSURL *, NSURL *);
	__block void(^copyFilesystemItem)(NSURL *, NSURL *);
	__block void(^removeFilesystemItem)(NSURL *);

	__block void(^subscribeToContentsOfDirectoryAtURL)(NSURL *);

	__block NSSet *result;
	__block NSError *outerError;
	__block BOOL outerErrored;
	__block BOOL outerCompleted;
	__block BOOL innerSuccess;
	__block NSError *innerError;


	before(^{
		testRootDirectoryURL = data[RCIOFileManagerSharedReactionExamplesTestRootDirectoryURL];
		createFilesystemItem = data[RCIOFileManagerSharedReactionExamplesCreateBlock];
		moveFilesystemItem = data[RCIOFileManagerSharedReactionExamplesMoveBlock];
		copyFilesystemItem = data[RCIOFileManagerSharedReactionExamplesCopyBlock];
		removeFilesystemItem = data[RCIOFileManagerSharedReactionExamplesRemoveBlock];

		subscribeToContentsOfDirectoryAtURL = ^(NSURL *url) {
			[[[RCIOFileManager contentsOfDirectoryAtURL:url options:0] skip:1] subscribeNext:^(RACSignal *signal) {
				result = pathSetFromURLArray([[signal collect] firstOrDefault:nil success:&innerSuccess error:&innerError]);
			} error:^(NSError *error) {
				outerError = error;
				outerErrored = YES;
			} completed:^{
				outerCompleted = YES;
			}];
		};

		result = nil;
		outerError = nil;
		outerErrored = NO;
		outerCompleted = NO;
		innerSuccess = NO;
		innerError = nil;
	});

	after(^{
		expect(outerError).to.beNil();
		expect(outerErrored).to.beFalsy();
		expect(outerCompleted).to.beFalsy();
	});

	describe(@"should react to", ^{
		__block NSURL *directoryURL;

		before(^{
			directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
			[[[NSFileManager alloc] init] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
		});

		describe(@"the directory being changed", ^{
			__block NSURL *newDirectoryURL;

			before(^{
				newDirectoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"newDirectory"];
			});

			it(@"by moving from the url", ^{
				subscribeToContentsOfDirectoryAtURL(directoryURL);

				moveFilesystemItem(directoryURL, newDirectoryURL);

				expect(innerError).willNot.beNil();
				expect(innerSuccess).to.beFalsy();
			});

			it(@"by moving to the url", ^{
				NSString *itemName = @"item";
				NSURL *itemURL = [directoryURL URLByAppendingPathComponent:itemName];
				NSURL *newItemURL = [newDirectoryURL URLByAppendingPathComponent:itemName];
				createFilesystemItem(itemURL);

				subscribeToContentsOfDirectoryAtURL(newDirectoryURL);

				moveFilesystemItem(directoryURL, newDirectoryURL);

				expect(result).will.equal(pathSetFromURLArray(@[ newItemURL ]));
				expect(innerError).to.beNil();
				expect(innerSuccess).to.beTruthy();
			});

			it(@"by copying to the url", ^{
				NSString *itemName = @"item";
				NSURL *itemURL = [directoryURL URLByAppendingPathComponent:itemName];
				NSURL *newItemURL = [newDirectoryURL URLByAppendingPathComponent:itemName];
				createFilesystemItem(itemURL);

				subscribeToContentsOfDirectoryAtURL(newDirectoryURL);

				copyFilesystemItem(directoryURL, newDirectoryURL);

				expect(result).will.equal(pathSetFromURLArray(@[ newItemURL ]));
				expect(innerError).to.beNil();
				expect(innerSuccess).to.beTruthy();
			});

			it(@"by removing from the url", ^{
				subscribeToContentsOfDirectoryAtURL(directoryURL);

				removeFilesystemItem(directoryURL);

				expect(innerError).willNot.beNil();
				expect(innerSuccess).to.beFalsy();
			});
		});

		describe(@"the contents of", ^{
			__block NSURL *itemURLOutsideDirectory;

			before(^{
				itemURLOutsideDirectory = [testRootDirectoryURL URLByAppendingPathComponent:@"item"];
			});

			describe(@"the directory being changed", ^{
				__block NSURL *itemURLInsideDirectory;
				__block NSURL *anotherItemURLInsideDirectory;

				before(^{
					itemURLInsideDirectory = [directoryURL URLByAppendingPathComponent:@"item"];
					anotherItemURLInsideDirectory = [directoryURL URLByAppendingPathComponent:@"another item"];
				});

				it(@"by creating an item in it", ^{
					subscribeToContentsOfDirectoryAtURL(directoryURL);

					createFilesystemItem(itemURLInsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[ itemURLInsideDirectory ]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by moving an item into it", ^{
					createFilesystemItem(itemURLOutsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					moveFilesystemItem(itemURLOutsideDirectory, itemURLInsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[ itemURLInsideDirectory ]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by moving an item out of it", ^{
					createFilesystemItem(itemURLInsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					moveFilesystemItem(itemURLInsideDirectory, itemURLOutsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by moving an item around in it", ^{
					createFilesystemItem(itemURLInsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					moveFilesystemItem(itemURLInsideDirectory, anotherItemURLInsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[ anotherItemURLInsideDirectory ]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by copying an item into it", ^{
					createFilesystemItem(itemURLOutsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					copyFilesystemItem(itemURLOutsideDirectory, itemURLInsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[ itemURLInsideDirectory ]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by copying an item around in it", ^{
					createFilesystemItem(itemURLInsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					copyFilesystemItem(itemURLInsideDirectory, anotherItemURLInsideDirectory);

					expect(result).will.equal((pathSetFromURLArray(@[ itemURLInsideDirectory, anotherItemURLInsideDirectory ])));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by removing an item in it", ^{
					createFilesystemItem(itemURLInsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					removeFilesystemItem(itemURLInsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});
			});

			describe(@"a subdirectory being changed", ^{
				__block NSURL *subdirectoryURL;
				__block NSURL *itemURLInsideSubdirectory;
				__block NSURL *anotherItemURLInsideSubdirectory;

				before(^{
					subdirectoryURL = [directoryURL URLByAppendingPathComponent:@"subdirectory"];
					[[[NSFileManager alloc] init] createDirectoryAtURL:subdirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
					itemURLInsideSubdirectory = [subdirectoryURL URLByAppendingPathComponent:@"item"];
					anotherItemURLInsideSubdirectory = [subdirectoryURL URLByAppendingPathComponent:@"another item"];
				});

				it(@"by creating an item in it", ^{
					subscribeToContentsOfDirectoryAtURL(directoryURL);

					createFilesystemItem(itemURLInsideSubdirectory);

					expect(result).will.equal((pathSetFromURLArray(@[ subdirectoryURL, itemURLInsideSubdirectory ])));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by moving an item into it", ^{
					createFilesystemItem(itemURLOutsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					moveFilesystemItem(itemURLOutsideDirectory, itemURLInsideSubdirectory);

					expect(result).will.equal((pathSetFromURLArray(@[ subdirectoryURL, itemURLInsideSubdirectory ])));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by moving an item out of it", ^{
					createFilesystemItem(itemURLInsideSubdirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					moveFilesystemItem(itemURLInsideSubdirectory, itemURLOutsideDirectory);

					expect(result).will.equal(pathSetFromURLArray(@[ subdirectoryURL ]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by moving an item around in it", ^{
					createFilesystemItem(itemURLInsideSubdirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					moveFilesystemItem(itemURLInsideSubdirectory, anotherItemURLInsideSubdirectory);

					expect(result).will.equal((pathSetFromURLArray(@[ subdirectoryURL, anotherItemURLInsideSubdirectory ])));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by copying an item into it", ^{
					createFilesystemItem(itemURLOutsideDirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					copyFilesystemItem(itemURLOutsideDirectory, itemURLInsideSubdirectory);

					expect(result).will.equal((pathSetFromURLArray(@[ subdirectoryURL, itemURLInsideSubdirectory ])));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by copying an item around in it", ^{
					createFilesystemItem(itemURLInsideSubdirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					copyFilesystemItem(itemURLInsideSubdirectory, anotherItemURLInsideSubdirectory);

					expect(result).will.equal((pathSetFromURLArray(@[ subdirectoryURL, itemURLInsideSubdirectory, anotherItemURLInsideSubdirectory ])));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});

				it(@"by removing an item in it", ^{
					createFilesystemItem(itemURLInsideSubdirectory);

					subscribeToContentsOfDirectoryAtURL(directoryURL);

					removeFilesystemItem(itemURLInsideSubdirectory);

					expect(result).will.equal(pathSetFromURLArray(@[ subdirectoryURL ]));
					expect(innerError).to.beNil();
					expect(innerSuccess).to.beTruthy();
				});
			});
		});
	});
});

sharedExamplesFor(RCIOFileManagerSharedExamplesName, ^(NSDictionary *data) {
	__block NSURL *testRootDirectoryURL;
	__block void(^createFilesystemItem)(NSURL *);
	__block BOOL success;
	__block NSError *error;

	before(^{
		testRootDirectoryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:randomString()];
		[[[NSFileManager alloc] init] createDirectoryAtURL:testRootDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];

		createFilesystemItem = data[RCIOFileManagerSharedExamplesCreateBlock];
		success = NO;
		error = nil;
	});

	after(^{
		[[[NSFileManager alloc] init] removeItemAtURL:testRootDirectoryURL error:NULL];
	});

	describe(@"file management", ^{
		__block NSURL *directoryURL;
		__block NSURL *itemURL;
		__block NSURL *newRootItemURL;
		__block NSURL *newItemURL;

		before(^{
			directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
			itemURL = [testRootDirectoryURL URLByAppendingPathComponent:@"item"];
			newRootItemURL = [testRootDirectoryURL URLByAppendingPathComponent:@"newItem"];
			newItemURL = [directoryURL URLByAppendingPathComponent:@"newItem"];

			[[[NSFileManager alloc] init] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
			createFilesystemItem(itemURL);
		});

		describe(@"moving", ^{
			it(@"should not move an item if the signal is not subscribed to", ^{
				[RCIOFileManager moveItemAtURL:itemURL toURL:newItemURL];

				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beFalsy();
			});

			it(@"should move an item twice if the signal is subscribed to twice", ^{
				RACSignal *signal = [RCIOFileManager moveItemAtURL:itemURL toURL:newItemURL];

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();

				[[[NSFileManager alloc] init] removeItemAtURL:newItemURL error:NULL];
				createFilesystemItem(itemURL);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beFalsy();

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});

			it(@"should not move an item if one exists at the destination", ^{
				createFilesystemItem(newItemURL);

				[[RCIOFileManager moveItemAtURL:itemURL toURL:newItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];
				
				expect(error).notTo.beNil();
				expect(success).to.beFalsy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});

			it(@"should move an item to a different directory", ^{
				[[RCIOFileManager moveItemAtURL:itemURL toURL:newItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});

			it(@"should rename an item", ^{
				[[RCIOFileManager moveItemAtURL:itemURL toURL:newRootItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
				expect(itemExistsAtURL(newRootItemURL)).to.beTruthy();
			});
		});

		describe(@"copying", ^{
			it(@"should not copy an item if the signal is not subscribed to", ^{
				[RCIOFileManager copyItemAtURL:itemURL toURL:newItemURL];

				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beFalsy();
			});

			it(@"should copy an item twice if the signal is subscribed to twice", ^{
				RACSignal *signal = [RCIOFileManager copyItemAtURL:itemURL toURL:newItemURL];

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();

				[[[NSFileManager alloc] init] removeItemAtURL:newItemURL error:NULL];
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beFalsy();

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});

			it(@"should not copy an item if one exists at the destination", ^{
				createFilesystemItem(newItemURL);

				[[RCIOFileManager copyItemAtURL:itemURL toURL:newItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).notTo.beNil();
				expect(success).to.beFalsy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});

			it(@"should copy an item to a different directory", ^{
				[[RCIOFileManager copyItemAtURL:itemURL toURL:newItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});

			it(@"should copy an item in the same directory", ^{
				[[RCIOFileManager copyItemAtURL:itemURL toURL:newRootItemURL] asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beTruthy();
				expect(itemExistsAtURL(newRootItemURL)).to.beTruthy();
			});
		});

		describe(@"removing", ^{
			it(@"should not remove an item if the signal is not subscribed to", ^{
				[RCIOFileManager removeItemAtURL:itemURL];

				expect(itemExistsAtURL(itemURL)).to.beTruthy();
			});

			it(@"should remove an item twice if the signal is subscribed to twice", ^{
				RACSignal *signal = [RCIOFileManager removeItemAtURL:itemURL];

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();

				createFilesystemItem(itemURL);
				expect(itemExistsAtURL(itemURL)).to.beTruthy();

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
				expect(itemExistsAtURL(itemURL)).to.beFalsy();
			});
		});
	});

	describe(@"directory listings", ^{
		it(@"should list items", ^{
			NSURL *directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
			NSURL *itemURL = [directoryURL URLByAppendingPathComponent:@"item"];
			[[[NSFileManager alloc] init] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
			createFilesystemItem(itemURL);

			RACSignal *signal = [[RCIOFileManager contentsOfDirectoryAtURL:testRootDirectoryURL options:0] firstOrDefault:nil success:&success error:&error];

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(signal).notTo.beNil();

			NSSet *result = pathSetFromURLArray([[signal collect] firstOrDefault:nil success:&success error:&error]);

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(result).to.equal((pathSetFromURLArray(@[ directoryURL, itemURL ])));
		});

		it(@"should skip resource forks", ^{
			NSURL *resourceForkURL = [testRootDirectoryURL URLByAppendingPathComponent:@"._resourceFork"];
			createFilesystemItem(resourceForkURL);

			RACSignal *signal = [[RCIOFileManager contentsOfDirectoryAtURL:testRootDirectoryURL options:0] firstOrDefault:nil success:&success error:&error];

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(signal).notTo.beNil();

			NSSet *result = pathSetFromURLArray([[signal collect] firstOrDefault:nil success:&success error:&error]);

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(result).to.equal((pathSetFromURLArray(@[])));
		});

		it(@"should skip subdirectory descendants", ^{
			NSURL *directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
			NSURL *itemURL = [directoryURL URLByAppendingPathComponent:@"item"];
			[[[NSFileManager alloc] init] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
			createFilesystemItem(itemURL);

			RACSignal *signal = [[RCIOFileManager contentsOfDirectoryAtURL:testRootDirectoryURL options:NSDirectoryEnumerationSkipsSubdirectoryDescendants] firstOrDefault:nil success:&success error:&error];

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(signal).notTo.beNil();

			NSSet *result = pathSetFromURLArray([[signal collect] firstOrDefault:nil success:&success error:&error]);

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(result).to.equal((pathSetFromURLArray(@[ directoryURL ])));
		});

		it(@"should skip hidden items", ^{
			NSURL *hiddenItemURL = [testRootDirectoryURL URLByAppendingPathComponent:@".hiddenItem"];
			createFilesystemItem(hiddenItemURL);

			RACSignal *signal = [[RCIOFileManager contentsOfDirectoryAtURL:testRootDirectoryURL options:NSDirectoryEnumerationSkipsHiddenFiles] firstOrDefault:nil success:&success error:&error];

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(signal).notTo.beNil();

			NSSet *result = pathSetFromURLArray([[signal collect] firstOrDefault:nil success:&success error:&error]);

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(result).to.equal((pathSetFromURLArray(@[])));
		});

		it(@"should error on the inner signal if a directory doesn't exist", ^{
			NSURL *nonExistingDirectoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"does not exist"];

			RACSignal *signal = [[RCIOFileManager contentsOfDirectoryAtURL:nonExistingDirectoryURL options:0] firstOrDefault:nil success:&success error:&error];

			expect(error).to.beNil();
			expect(success).to.beTruthy();
			expect(signal).notTo.beNil();

			[[signal collect] firstOrDefault:nil success:&success error:&error];

			expect(error).toNot.beNil();
			expect(success).toNot.beTruthy();
		});

		itShouldBehaveLike(RCIOFileManagerSharedReactionExamples, ^{
			return @{
				RCIOFileManagerSharedReactionExamplesTestRootDirectoryURL: testRootDirectoryURL,
				RCIOFileManagerSharedReactionExamplesCreateBlock: createFilesystemItem,
				RCIOFileManagerSharedReactionExamplesMoveBlock: [^(NSURL *source, NSURL *destination) {
					[[[RCIOFileManager moveItemAtURL:source toURL:destination] ignoreValues] first];
				} copy],
				RCIOFileManagerSharedReactionExamplesCopyBlock: [^(NSURL *source, NSURL *destination) {
					[[[RCIOFileManager copyItemAtURL:source toURL:destination] ignoreValues] first];
				} copy],
				RCIOFileManagerSharedReactionExamplesRemoveBlock: [^(NSURL *url) {
					[[[RCIOFileManager removeItemAtURL:url] ignoreValues] first];
				} copy]
			};
		});

#if !TARGET_OS_IPHONE
		// If we're on OS X this should work even without using RCIOFileManager.
		itShouldBehaveLike(RCIOFileManagerSharedReactionExamples, ^{
			return @{
				RCIOFileManagerSharedReactionExamplesTestRootDirectoryURL: testRootDirectoryURL,
				RCIOFileManagerSharedReactionExamplesCreateBlock: createFilesystemItem,
				RCIOFileManagerSharedReactionExamplesMoveBlock: [^(NSURL *source, NSURL *destination) {
					[[[NSFileManager alloc] init] moveItemAtURL:source toURL:destination error:NULL];
				} copy],
				RCIOFileManagerSharedReactionExamplesCopyBlock: [^(NSURL *source, NSURL *destination) {
					[[[NSFileManager alloc] init] copyItemAtURL:source toURL:destination error:NULL];
				} copy],
				RCIOFileManagerSharedReactionExamplesRemoveBlock: [^(NSURL *url) {
					[[[NSFileManager alloc] init] removeItemAtURL:url error:NULL];
				} copy]
			};
		});
#endif
	});
});

SharedExampleGroupsEnd

SpecBegin(RCIOFileManager)

itShouldBehaveLike(RCIOFileManagerSharedExamplesName, @{ RCIOFileManagerSharedExamplesCreateBlock: [^(NSURL *url) {
	touch(url);
} copy] });

itShouldBehaveLike(RCIOFileManagerSharedExamplesName, @{ RCIOFileManagerSharedExamplesCreateBlock: [^(NSURL *url) {
	[[[NSFileManager alloc] init] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
} copy] });

SpecEnd
