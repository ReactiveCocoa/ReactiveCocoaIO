//
//  RCIOWeakDictionary.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 16/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOWeakDictionary.h"

@interface RCIOWeakWrapper : NSObject

+ (instancetype)wrapperWithValue:(id)value;

@property (nonatomic, weak) id value;

@end

@implementation RCIOWeakDictionary {
	NSMutableDictionary *_backing;
}

+ (instancetype)dictionary {
	return [[self alloc] init];
}

- (id)init {
	self = [super init];
	if (self == nil) return nil;
	_backing = [NSMutableDictionary dictionary];
	return self;
}

- (id)objectForKeyedSubscript:(id)key {
	@synchronized (self) {
		RCIOWeakWrapper *wrapper = _backing[key];
		return wrapper.value;
	}
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key {
	NSParameterAssert(obj != nil);
	@weakify(self);
	
	@synchronized (self) {
		RCIOWeakWrapper *wrapper = [RCIOWeakWrapper wrapperWithValue:obj];
		[obj rac_addDeallocDisposable:[RACDisposable disposableWithBlock:^{
			@strongify(self);
			@synchronized (self) {
				if (wrapper == [self->_backing objectForKey:key]) [self->_backing removeObjectForKey:key];
			}
		}]];
		_backing[key] = wrapper;
	}
}

- (void)removeObjectForKey:(id)key {
	@synchronized (self) {
		[_backing removeObjectForKey:key];
	};
}

@end

@implementation RCIOWeakWrapper

+ (instancetype)wrapperWithValue:(id)value {
	RCIOWeakWrapper *wrapper = [[self alloc] init];
	wrapper->_value = value;
	return wrapper;
}

@end
