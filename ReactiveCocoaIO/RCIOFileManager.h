//
//  RCIOFileManager.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/11/13.
//
//

#import <Foundation/Foundation.h>

@class RACSignal;

typedef struct {
	/// An operation failed because a call to the underlying framework code failed.
	/// Check the error's user info's `NSUnderlyingErrorKey` value for details.
	const NSInteger underlyingError;

	/// RCIOFileManager failed to interface with the FSEvents API.
	const NSInteger fsEventsError;
} RCIOFileManagerErrorCodesList;

@interface RCIOFileManager : NSObject

/// The domain for errors sent by RCIOFileManager.
+ (NSString *)errorDomain;

/// The list of error codes for errors sent by RCIOFileManager.
+ (RCIOFileManagerErrorCodesList)errorCodes;

/// Lists the contents of a directory.
///
/// url     - The url of the directory.
/// options - A bitmask of `NSDirectoryEnumerationOptions` specifying the items
///           that should not be included in the results.
///
/// Returns a signal that sends signals of urls, one for each item contained in
/// the directory currently pointed at by `url`. A new signal is sent each time
/// the directory the url points to changes, or the current directory's contents
/// do, even if the previous signal has not completed yet. Note that on iOS,
/// this only happens for changes caused by ReactiveCocoaIO code.
+ (RACSignal *)contentsOfDirectoryAtURL:(NSURL *)url options:(NSDirectoryEnumerationOptions)options;

/// Moves or renames a file system item.
///
/// sourceURL      - The url of the file system item to move or rename.
/// destinationURL - The url the file system item will have after a successful
///                  move or rename.
///
/// Returns a signal that executes the move or rename when subscribed to. If the
/// subscription is disposed of before the move or rename is completed the
/// operation is halted. A possibly incomplete copy of the file system item
/// might exist at `destinationURL` in that case.
+ (RACSignal *)moveItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL;

/// Copies a file system item.
///
/// sourceURL      - The url of the file system item to copy.
/// destinationURL - The url of the new copy of the file system item.
///
/// Returns a signal that executes the copy when subscribed to. If the
/// subscription is disposed of before the copy is completed the operation is
/// halted. A possibly incomplete copy of the file system item might exist at
/// `destinationURL` in that case.
+ (RACSignal *)copyItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL;

/// Removes a file system item.
///
/// url - The url of the file system item to remove.
///
/// Returns a signal that executes the removal when subscribed to.
+ (RACSignal *)removeItemAtURL:(NSURL *)url;

@end
