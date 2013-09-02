//
//  RCIODirectory.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIODirectory+Private.h"
#import "RCIOItem+Private.h"

#import "NSURL+TrailingSlash.h"

static NSString * const RCIODirectoryChangeTypeAdd = @"RCIODirectoryChangeTypeAdd";
static NSString * const RCIODirectoryChangeTypeRemove = @"RCIODirectoryChangeTypeRemove";

@interface RCIODirectory ()

@property (nonatomic, weak) RACSubject *childrenChannel;

- (NSMutableArray *)loadChildren;

@end

@implementation RCIODirectory

#pragma mark RCIOItem

+ (instancetype)createItemAtURL:(NSURL *)url {
	if (![[[NSFileManager alloc] init] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL]) return nil;
	return [[self alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
	url = url.URLByAppendingTrailingSlash;
	return [super initWithURL:url];
}

- (void)didMoveToURL:(NSURL *)url {
	url = url.URLByAppendingTrailingSlash;
	[super didMoveToURL:url];
}

- (void)didCopyToURL:(NSURL *)url {
	url = url.URLByAppendingTrailingSlash;
	[super didCopyToURL:url];
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
	
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		__block volatile uint32_t __isCancelled = 0;
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		[disposable addDisposable:[RACDisposable disposableWithBlock:^{
			OSAtomicOr32Barrier(1, &__isCancelled);
		}]];
		
		[disposable addDisposable:[[RACScheduler scheduler] schedule:^{
			
			RACSubject *childrenChannel = self.childrenChannel;
			if (childrenChannel == nil) {
				childrenChannel = [RACSubject subject];
				self.childrenChannel = childrenChannel;
			}
			
			NSArray *children = [self loadChildren];
			
			[disposable addDisposable:[[[[childrenChannel scanWithStart:children reduce:^id(NSMutableArray *children, RACTuple *change) {
				RACTupleUnpack(NSString *type, RCIOItem *item) = change;
				
				if (type == RCIODirectoryChangeTypeAdd) {
					NSUInteger index = [children indexOfObject:item inSortedRange:NSMakeRange(0, children.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(RCIOItem *item1, RCIOItem *item2) {
						return [item1.urlBacking.lastPathComponent localizedStandardCompare:item2.urlBacking.lastPathComponent];
					}];
					[children insertObject:item atIndex:index];
				} else {
					[children removeObject:item];
				}
				
				return children;
			}] startWith:children] map:^ NSArray * (NSArray *content) {
				if (__isCancelled != 0) return @[];
				
				NSMutableArray *processedContent = [NSMutableArray arrayWithCapacity:content.count];
				processContent(content, processedContent, options, &__isCancelled);
				
				return processedContent;
			}] subscribe:subscriber]];
		}]];
		
		return disposable;
	}];
}

- (RACSignal *)childrenSignal {
	return [self childrenSignalWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (void)didAddItem:(RCIOItem *)item {
	NSParameterAssert(item != nil);
	[self.childrenChannel sendNext:[RACTuple tupleWithObjects:RCIODirectoryChangeTypeAdd, item, nil]];
}

- (void)didRemoveItem:(RCIOItem *)item {
	NSParameterAssert(item != nil);
	[self.childrenChannel sendNext:[RACTuple tupleWithObjects:RCIODirectoryChangeTypeRemove, item, nil]];
}

#pragma mark - Private Methods

- (NSMutableArray *)loadChildren {
	if (self.urlBacking == nil) return nil;
	NSMutableArray *children = [NSMutableArray array];
	for (NSURL *url in [[[NSFileManager alloc] init] enumeratorAtURL:self.urlBacking includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
		RCIOItem *child = [RCIOItem loadItemFromURL:url.URLByResolvingSymlinksInPath];
		if (child != nil) [children addObject:child];
	}
	return children;
}

@end
