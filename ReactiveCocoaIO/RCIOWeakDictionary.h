//
//  RCIOWeakDictionary.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 16/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCIOWeakDictionary : NSObject

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id)key;

@end
