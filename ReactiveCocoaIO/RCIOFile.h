//
//  RCIOFile.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import <ReactiveCocoaIO/RCIOItem.h>

@class RACPropertySubject;

@interface RCIOFile : RCIOItem

// Returns a property subject for the receiver's encoding.
@property (nonatomic, strong, readonly) RACPropertySubject *encodingSubject;

// Returns a property subject for the receiver's content.
@property (nonatomic, strong, readonly) RACPropertySubject *contentSubject;

// Saves the receiver to it's persistence mechanism.
//
// Returns a signal that sends the saved item and completes.
- (RACSignal *)save;

@end
