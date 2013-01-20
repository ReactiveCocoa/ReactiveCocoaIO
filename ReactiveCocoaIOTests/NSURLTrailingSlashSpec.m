//
//  NSURLTrailingSlashSpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 20/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "NSURL+TrailingSlash.h"

SpecBegin(NSURLTrailingSlash)

describe(@"NSURL+TrailingSlash", ^{
	__block NSURL *urlWithoutTrailingSlash;
	__block NSURL *urlWithTrailingSlash;
	
	beforeAll(^{
		// Create URLs for files that don't exist on the file system to avoid NSURL magic
		urlWithoutTrailingSlash = [NSURL URLWithString:@"file://localhost/directorythatdoesntexist/test"];
		urlWithTrailingSlash = [NSURL URLWithString:@"file://localhost/directorythatdoesntexist/test/"];
	});
	
	it(@"should detect a trailing slash", ^{
		expect(urlWithoutTrailingSlash.hasTrailingSlash).to.beFalsy();
		expect(urlWithTrailingSlash.hasTrailingSlash).to.beTruthy();
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
});

SpecEnd
