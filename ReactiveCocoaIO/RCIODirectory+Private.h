//
//  RCIODirectory+Private.h
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import "RCIODirectory.h"

@interface RCIODirectory ()

// Called after `item` has been added to the receiver.
- (void)didAddItem:(RCIOItem *)item;

// Called after `item` has been removed from the receiver.
- (void)didRemoveItem:(RCIOItem *)item;

@end
