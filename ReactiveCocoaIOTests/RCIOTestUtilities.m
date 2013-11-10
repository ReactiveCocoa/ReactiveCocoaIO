//
//  RCIOTestUtilities.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import "RCIOTestUtilities.h"

NSString *randomString() {
	return [NSString stringWithFormat:@"%@", @(arc4random_uniform(8999999) + 1000000)];
};

BOOL itemExistsAtURL(NSURL *url) {
	return [[[NSFileManager alloc] init] fileExistsAtPath:url.path];
}

BOOL touch(NSURL *url) {
	return [@"" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}
