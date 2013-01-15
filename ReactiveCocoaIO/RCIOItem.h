//
//  RCIOItem.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 9/26/12.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal, RACPropertySubject, RCIODirectory;

// Specifies how the filesystem item should be accessed.
//
// RCIOItemModeReadWrite       - Access the item for both reading and writing.
//                               If the item doesn't exist on the filesystem, it
//                               will be created.
// RCIOItemModeExclusiveAccess - Ensure the returned RCIOItem is the only handle
//                               to the filesystem item. Doesn't currently
//                               provide any guarantee to that other than
//                               ensuring the filesystem item didn't exist
//                               before the call.
typedef enum : NSUInteger {
	RCIOItemModeReadWrite = 0,
	RCIOItemModeExclusiveAccess = 1 << 8,
} RCIOItemMode;

@interface RCIOItem : NSObject

// Returns a signal that sends the item at `url`, then completes.
//
// url  - The url of the filesystem item to access.
// mode - Specifies how the filesystem item should be accessed.
//
// Note that the RCIOItem class itself does not support creating items that
// do not already exist on the filesystem. Use the subclasses instead.
+ (RACSignal *)itemWithURL:(NSURL *)url mode:(RCIOItemMode)mode;

// Equivalent to `-itemWithURL:url mode:RCIOItemModeReadWrite`.
+ (RACSignal *)itemWithURL:(NSURL *)url;

// The url of the receiver.
- (NSURL *)url;

// Returns a signal that sends the URL of the receiver.
@property (nonatomic, strong, readonly) RACSignal *urlSignal;

// The name of the receiver.
- (NSString *)name;

// Returns a signal that sends the name of the receiver.
@property (nonatomic, strong, readonly) RACSignal *nameSignal;

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

// Returns a property subject for the receiver's extended attribute identified
// by `key`.
- (RACPropertySubject *)extendedAttributeSubjectForKey:(NSString *)key;

@end
