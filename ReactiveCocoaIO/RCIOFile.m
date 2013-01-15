//
//  RCIOFile.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 10/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOFile.h"
#import "RCIOItem+Private.h"

@interface RCIOFile ()

@property (nonatomic) NSStringEncoding encodingBacking;
@property (nonatomic, strong) NSString *contentBacking;
@property (nonatomic, getter = isLoaded) BOOL loaded;

- (void)loadFileIfNeeded;

@end

@implementation RCIOFile

#pragma mark RCIOItem

- (instancetype)initWithURL:(NSURL *)url {
	self = [super initWithURL:url];
	if (self == nil) return nil;
	
	_encodingBacking = NSUTF8StringEncoding;
	_contentBacking = @"";
	
	return self;
}

- (RACSignal *)create {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		CANCELLATION_DISPOSABLE(disposable);
		
		[disposable addDisposable:[fileSystemScheduler() schedule:^{
			@strongify(self);
			NSURL *url = self.urlBacking;
			NSError *error = nil;
			
			if ([NSFileManager.defaultManager fileExistsAtPath:url.path] || ![self.contentBacking writeToURL:url atomically:NO encoding:self.encodingBacking error:&error]) {
				[subscriber sendError:error];
				return;
			}
			self.loaded = YES;
			[disposable addDisposable:[super.create subscribe:subscriber]];
		}]];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

#pragma mark RCIOFile

- (RACPropertySubject *)encodingSubject {
	@weakify(self);
	RACPropertySubject *subject = [RACPropertySubject property];
	RACBinding *encodingBinding = subject.binding;
	RACScheduler *callingScheduler = currentScheduler();
	
	[fileSystemScheduler() schedule:^{
		@strongify(self);
		[self loadFileIfNeeded];
		RACBinding *encodingBackingBinding = RACBind(self.encodingBacking);
		[[encodingBackingBinding deliverOn:callingScheduler] subscribe:encodingBinding];
		[callingScheduler schedule:^{
			[[[encodingBinding deliverOn:fileSystemScheduler()] map:^(NSNumber *encoding) {
				if (encoding == nil || encoding.unsignedIntegerValue == 0) encoding = @(NSUTF8StringEncoding);
				return encoding;
			}] subscribe:encodingBackingBinding];
		}];
	}];
	
	return subject;
}

- (RACPropertySubject *)contentSubject {
	@weakify(self);
	RACPropertySubject *subject = [RACPropertySubject property];
	RACBinding *contentBinding = subject.binding;
	RACScheduler *callingScheduler = currentScheduler();
	
	[fileSystemScheduler() schedule:^{
		@strongify(self);
		[self loadFileIfNeeded];
		RACBinding *contentBackingBinding = RACBind(self.contentBacking);
		[[contentBackingBinding deliverOn:callingScheduler] subscribe:contentBinding];
		[callingScheduler schedule:^{
			[[[contentBinding deliverOn:fileSystemScheduler()] filter:^BOOL(NSString *content) {
				return content != nil;
			}] subscribe:contentBackingBinding];
		}];
	}];
	
	return subject;
}

- (RACSignal *)save {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		return [fileSystemScheduler() schedule:^{
			@strongify(self);
			NSURL *url = self.urlBacking;
			NSError *error = nil;
			
			if (!url) {
				[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
				return;
			}
			
			if (!self.loaded) {
				[subscriber sendNext:self];
				[subscriber sendCompleted];
				return;
			}
			
			// Don't save atomically so we don't lose extended attributes
			if (![self.contentBacking writeToURL:url atomically:NO encoding:self.encodingBacking error:&error]) {
				[subscriber sendError:error];
			} else {
				[subscriber sendNext:self];
				[subscriber sendCompleted];
			}
		}];
	}] deliverOn:RACScheduler.currentScheduler];
}

#pragma mark Private Methods

- (void)loadFileIfNeeded {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	if (self.loaded) return;
	NSStringEncoding encoding;
	self.contentBacking = [NSString stringWithContentsOfURL:self.urlBacking usedEncoding:&encoding error:NULL];
	self.encodingBacking = encoding;
	self.loaded = YES;
}

@end
