//
//  RCIOItem.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 9/26/12.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal, RACChannelTerminal, RCIODirectory;

// Specifies how the file system item should be accessed.
//
// RCIOItemModeReadWrite       - Access the item for both reading and writing.
//                               If the item doesn't exist on the file system,
//                               it will be created.
// RCIOItemModeExclusiveAccess - Ensure the returned RCIOItem is the only handle
//                               to the file system item. Doesn't currently
//                               provide any guarantee to that other than
//                               ensuring the file system item didn't exist
//                               before the call.
typedef enum : NSUInteger {
	RCIOItemModeReadWrite = 0,
	RCIOItemModeExclusiveAccess = 1 << 8,
} RCIOItemMode;

@interface RCIOItem : NSObject

// Returns a signal that sends the item at `url`, then completes.
//
// url  - The url of the file system item to access.
// mode - Specifies how the file system item should be accessed.
//
// Note that the RCIOItem class itself does not support creating items that
// do not already exist on the file system. Use the subclasses instead.
+ (RACSignal *)itemWithURL:(NSURL *)url mode:(RCIOItemMode)mode;

// Equivalent to `-itemWithURL:url mode:RCIOItemModeReadWrite`.
+ (RACSignal *)itemWithURL:(NSURL *)url;

// The url of the receiver.
- (NSURL *)url;

// Returns a signal that sends the URL of the receiver.
@property (nonatomic, strong, readonly) RACSignal *urlSignal;

// Returns a signal that sends the parent directory of the receiver.
@property (nonatomic, strong, readonly) RACSignal *parentSignal;

@end

@interface RCIOItem (FileManagement)

// Moves the receiver to the given directory.
//
// destination   - An optional RCIODirectory to which the receiver is
//                 moved.
// newName       - An optional name to rename the file to.
// shouldReplace - Indicates if the operation should replace any existing file.
//
// Returns a signal that sends the moved RCIOItem and completes.
- (RACSignal *)moveTo:(RCIODirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace;

// Copy the receiver to the given directory.
//
// destination   - An optional RCIODirectory to which the receiver is
//                 copied.
// newName       - An optional name to rename the file to.
// shouldReplace - Indicates if the operation should replace any existing file.
//
// Returns a signal that sends the newly copied RCIOItem and completes.
- (RACSignal *)copyTo:(RCIODirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace;

// Equivalent to -moveTo:destination withName:nil replaceExisting:YES.
- (RACSignal *)moveTo:(RCIODirectory *)destination;

// Equivalent to -copyTo:destination withName:nil replaceExisting:YES.
- (RACSignal *)copyTo:(RCIODirectory *)destination;

// Equivalent to -moveTo:nil withName:newName replaceExisting:YES.
- (RACSignal *)renameTo:(NSString *)newName;

// Duplicates the receiver.
//
// Returns a signal that sends the duplicate and completes.
- (RACSignal *)duplicate;

// Deletes the receiver.
//
// Returns a signal that sends the deleted item and completed.
- (RACSignal *)delete;

@end

@interface RCIOItem (ExtendedAttributes)

// Returns a channel terminal for the receiver's extended attribute identified
// by `key`.
- (RACChannelTerminal *)extendedAttributeChannelForKey:(NSString *)key;

@end
