//
//  RCIOTestUtilities.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import <Foundation/Foundation.h>

// Returns a pseudorandom string made of nine digits.
extern NSString *randomString();

// Returns whether a file system item exists at the given url.
extern BOOL itemExistsAtURL(NSURL *url);

// Creates an empty file at the given url. The containing directory must exist.
extern BOOL touch(NSURL *url);

// Returns a set of paths of the urls in the array.
extern NSSet *pathSetFromURLArray(NSArray *array);
