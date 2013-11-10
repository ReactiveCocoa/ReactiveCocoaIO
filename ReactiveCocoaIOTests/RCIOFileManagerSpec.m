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
static NSString * const RCIOFileManagerSharedExamplesCreateFilesystemItemBlock = @"RCIOFileManagerSharedExamplesCreateFilesystemItemBlock";

SharedExampleGroupsBegin(RCIOFileManager)

sharedExamplesFor(RCIOFileManagerSharedExamplesName, ^(NSDictionary *data) {
	__block NSURL *testRootDirectoryURL;
	__block NSURL *directoryURL;
	__block NSURL *itemURL;
	__block NSURL *newRootItemURL;
	__block NSURL *newItemURL;
	__block void(^createFilesystemItem)(NSURL *);
	__block BOOL success;
	__block NSError *error;

	before(^{
		testRootDirectoryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:randomString()];
		directoryURL = [testRootDirectoryURL URLByAppendingPathComponent:@"directory"];
		itemURL = [testRootDirectoryURL URLByAppendingPathComponent:@"item"];
		newRootItemURL = [testRootDirectoryURL URLByAppendingPathComponent:@"newItem"];
		newItemURL = [directoryURL URLByAppendingPathComponent:@"newItem"];
		createFilesystemItem = data[RCIOFileManagerSharedExamplesCreateFilesystemItemBlock];
		success = NO;
		error = nil;

		[[[NSFileManager alloc] init] createDirectoryAtURL:testRootDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
		[[[NSFileManager alloc] init] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
		createFilesystemItem(itemURL);
	});

	after(^{
		[[[NSFileManager alloc] init] removeItemAtURL:testRootDirectoryURL error:NULL];
	});

	describe(@"file management", ^{
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
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
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
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();

				[signal asynchronousFirstOrDefault:nil success:&success error:&error];

				expect(error).to.beNil();
				expect(success).to.beTruthy();
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
				expect(itemExistsAtURL(newItemURL)).to.beTruthy();
			});
		});

		describe(@"removing", ^{
			it(@"should not remove an item if the signal is not subscribed to", ^{
				[RCIOFileManager removeItemAtURL:itemURL];

				expect(itemExistsAtURL(itemURL)).to.beFalsy();
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
		
	});
});

SharedExampleGroupsEnd

SpecBegin(RCIOFileManager)

itShouldBehaveLike(RCIOFileManagerSharedExamplesName, @{ RCIOFileManagerSharedExamplesCreateFilesystemItemBlock: [^(NSURL *url) {
	touch(url);
} copy] });

itShouldBehaveLike(RCIOFileManagerSharedExamplesName, @{ RCIOFileManagerSharedExamplesCreateFilesystemItemBlock: [^(NSURL *url) {
	[[[NSFileManager alloc] init] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
} copy] });

SpecEnd
