//
//  NSURLTrailingSlashSpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 20/01/2013.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import "NSURL+TrailingSlash.h"

SpecBegin(NSURLTrailingSlash)

describe(@"NSURL+TrailingSlash", ^{
	__block NSURL *urlWithoutTrailingSlash;
	__block NSURL *urlWithTrailingSlash;
	__block NSURL *fileURLWithoutTrailingSlash;
	__block NSURL *fileURLWithTrailingSlash;
	__block NSURL *directoryURLWithoutTrailingSlash;
	__block NSURL *directoryURLWithTrailingSlash;
	
	beforeAll(^{
		// URLs for files that don't exist on the file system to avoid NSURL magic
		urlWithoutTrailingSlash = [NSURL URLWithString:@"file://localhost/directory%20that%20doesn't%20exist/test"];
		urlWithTrailingSlash = [NSURL URLWithString:@"file://localhost/directory%20that%20doesn't%20exist/test/"];
		// URLs for files that exist on the file system to trigger NSURL magic
		fileURLWithoutTrailingSlash = [NSURL URLWithString:@"file://localhost/etc/hosts"];
		fileURLWithTrailingSlash = [NSURL URLWithString:@"file://localhost/etc/hosts/"];
		directoryURLWithoutTrailingSlash = [NSURL URLWithString:@"file://localhost/etc"];
		directoryURLWithTrailingSlash = [NSURL URLWithString:@"file://localhost/etc/"];
	});
	
	it(@"should detect a trailing slash", ^{
		expect(urlWithoutTrailingSlash.hasTrailingSlash).to.beFalsy();
		expect(urlWithTrailingSlash.hasTrailingSlash).to.beTruthy();
	});
	
	it(@"should detect a trailing slash in file urls", ^{
		expect(fileURLWithoutTrailingSlash.hasTrailingSlash).to.beFalsy();
		expect(fileURLWithTrailingSlash.hasTrailingSlash).to.beTruthy();
		expect(directoryURLWithoutTrailingSlash.hasTrailingSlash).to.beFalsy();
		expect(directoryURLWithTrailingSlash.hasTrailingSlash).to.beTruthy();
	});
	
	it(@"should remove trailing slashes from urls with trailing slashes", ^{
		expect(urlWithTrailingSlash.URLByDeletingTrailingSlash).to.equal(urlWithoutTrailingSlash);
	});
	
	it(@"should not remove trailing slashes from urls without trailing slashes", ^{
		expect(urlWithoutTrailingSlash.URLByDeletingTrailingSlash).to.equal(urlWithoutTrailingSlash);
	});
	
	it(@"should add trailing slashes to urls without trailing slashes", ^{
		expect(urlWithoutTrailingSlash.URLByAppendingTrailingSlash).to.equal(urlWithTrailingSlash);
	});
	
	it(@"should not add trailing slashes to urls with trailing slashes", ^{
		expect(urlWithTrailingSlash.URLByAppendingTrailingSlash).to.equal(urlWithTrailingSlash);
	});
	
	it(@"should remove trailing slashes from file urls with trailing slashes", ^{
		expect(fileURLWithTrailingSlash.URLByDeletingTrailingSlash).to.equal(fileURLWithoutTrailingSlash);
	});
	
	it(@"should not remove trailing slashes from file urls without trailing slashes", ^{
		expect(fileURLWithoutTrailingSlash.URLByDeletingTrailingSlash).to.equal(fileURLWithoutTrailingSlash);
	});
	
	it(@"should add trailing slashes to file urls without trailing slashes", ^{
		expect(fileURLWithoutTrailingSlash.URLByAppendingTrailingSlash).to.equal(fileURLWithTrailingSlash);
	});
	
	it(@"should not add trailing slashes to file urls with trailing slashes", ^{
		expect(fileURLWithTrailingSlash.URLByAppendingTrailingSlash).to.equal(fileURLWithTrailingSlash);
	});

	it(@"should remove trailing slashes from directory urls with trailing slashes", ^{
		expect(directoryURLWithTrailingSlash.URLByDeletingTrailingSlash).to.equal(directoryURLWithoutTrailingSlash);
	});
	
	it(@"should not remove trailing slashes from directory urls without trailing slashes", ^{
		expect(directoryURLWithoutTrailingSlash.URLByDeletingTrailingSlash).to.equal(directoryURLWithoutTrailingSlash);
	});
	
	it(@"should add trailing slashes to directory urls without trailing slashes", ^{
		expect(directoryURLWithoutTrailingSlash.URLByAppendingTrailingSlash).to.equal(directoryURLWithTrailingSlash);
	});
	
	it(@"should not add trailing slashes to directory urls with trailing slashes", ^{
		expect(directoryURLWithTrailingSlash.URLByAppendingTrailingSlash).to.equal(directoryURLWithTrailingSlash);
	});
});

SpecEnd
