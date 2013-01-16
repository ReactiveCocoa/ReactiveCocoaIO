//
//  RCIOWeakDictionary.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 16/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import <Foundation/Foundation.h>

// A dictionary object that stores objects weakly.
//
// The dictionary will only keep weak references to objects. Objects will be
// allowed to deallocate if all references to them are weak.
@interface RCIOWeakDictionary : NSObject

// Returns a new weak dictionary.
+ (instancetype)dictionary;

// Returns the object stored weakly at `key`.
- (id)objectForKeyedSubscript:(id)key;

// Stores `obj` weakly at `key`.
- (void)setObject:(id)obj forKeyedSubscript:(id)key;

// Removes the object stored at `key`.
- (void)removeObjectForKey:(id)key;

@end
