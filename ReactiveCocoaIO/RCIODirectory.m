//
//  RCIODirectory.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIODirectory+Private.h"
#import "RCIOItem+Private.h"

static NSString * const RCIODirectoryChangeTypeAdd = @"RCIODirectoryChangeTypeAdd";
static NSString * const RCIODirectoryChangeTypeRemove = @"RCIODirectoryChangeTypeRemove";

@interface RCIODirectory ()

@property (nonatomic, weak) RACSubject *childrenChannel;

- (NSMutableArray *)loadChildren;

@end

@implementation RCIODirectory

#pragma mark RCIOItem

+ (instancetype)createItemAtURL:(NSURL *)url {
	if (![NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL]) return nil;
	return [[self alloc] initWithURL:url];
}

#pragma mark RCIODirectory

static void processContent(NSArray *input, NSMutableArray *output, NSDirectoryEnumerationOptions options, volatile uint32_t *cancel) {
	@autoreleasepool {
		for (RCIOItem *item in input) {
			// Break out if cancelled
			if (*cancel != 0) break;
			
			// Skip deleted files
			if (item.urlBacking == nil) continue;
			
			// Skip hidden files
			if ((options & NSDirectoryEnumerationSkipsHiddenFiles) && ([item.urlBacking.lastPathComponent characterAtIndex:0] == L'.')) continue;
			
			[output addObject:item];
			
			// Merge in descendants
			if (!(options & NSDirectoryEnumerationSkipsSubdirectoryDescendants) && [item isKindOfClass:RCIODirectory.class]) processContent([(RCIODirectory *)item loadChildren], output, options, cancel);
		}
	}
}

- (RACSignal *)childrenSignalWithOptions:(NSDirectoryEnumerationOptions)options {
	NSParameterAssert(!(options & NSDirectoryEnumerationSkipsPackageDescendants));
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		CANCELLATION_DISPOSABLE(disposable);
		
		[disposable addDisposable:[fileSystemScheduler() schedule:^{
			
			RACSubject *childrenChannel = self.childrenChannel;
			if (childrenChannel == nil) {
				childrenChannel = [RACSubject subject];
				self.childrenChannel = childrenChannel;
			}
			
			NSArray *children = [self loadChildren];
			
			[disposable addDisposable:[[[[childrenChannel scanWithStart:children combine:^id(NSMutableArray *children, RACTuple *change) {
				RACTupleUnpack(NSString *type, RCIOItem *item) = change;
				
				if (type == RCIODirectoryChangeTypeAdd) {
					[children addObject:item];
				} else {
					[children removeObject:item];
				}
				
				return children;
			}] startWith:children] map:^ NSArray * (NSArray *content) {
				IF_CANCELLED_RETURN(@[]);
				
				NSMutableArray *processedContent = [NSMutableArray arrayWithCapacity:content.count];
				processContent(content, processedContent, options, CANCELLATION_FLAG);
				
				return processedContent;
			}] subscribe:subscriber]];
		}]];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

- (RACSignal *)childrenSignal {
	return [self childrenSignalWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (void)didAddItem:(RCIOItem *)item {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	NSParameterAssert(item != nil);
	[self.childrenChannel sendNext:[RACTuple tupleWithObjects:RCIODirectoryChangeTypeAdd, item, nil]];
}

- (void)didRemoveItem:(RCIOItem *)item {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	NSParameterAssert(item != nil);
	[self.childrenChannel sendNext:[RACTuple tupleWithObjects:RCIODirectoryChangeTypeRemove, item, nil]];
}

#pragma mark - Private Methods

- (NSMutableArray *)loadChildren {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	if (self.urlBacking == nil) return nil;
	NSMutableArray *children = [NSMutableArray array];
	for (NSURL *url in [NSFileManager.defaultManager enumeratorAtURL:self.urlBacking includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
		RCIOItem *child = [RCIOItem loadItemFromURL:url];
		if (child != nil) [children addObject:child];
	}
	return children;
}

@end
