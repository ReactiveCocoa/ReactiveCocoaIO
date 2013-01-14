//
//  RCIODirectory.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import <ReactiveCocoaIO/RCIOItem.h>

@interface RCIODirectory : RCIOItem

// Get the receiver's children.
//
// options            - A mask of NSDirectoryEnumerationOptions with which to
//                      filter the children sent by the signal. May not include
//                      NSDirectoryEnumerationSkipsPackageDescendants.
//
// Returns a signal that sends arrays of the receiver's children.
- (RACSignal *)childrenSignalWithOptions:(NSDirectoryEnumerationOptions)options;

// Equivalent to -childrenSignalWithOptions:
// NSDirectoryEnumerationSkipsSubdirectoryDescendants |
// NSDirectoryEnumerationSkipsHiddenFiles.
- (RACSignal *)childrenSignal;

@end
