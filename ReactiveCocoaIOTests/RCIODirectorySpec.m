//
//  RCIODirectorySpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 15/01/2013.
//  Copyright (c) 2013 Uri Baghin. All rights reserved.
//

#import "RCIOItemExamples.h"

SpecBegin(RCIODirectory)

describe(@"RCIODirectory", ^{
	itShouldBehaveLike(RCIOItemExamples, @{ RCIOItemExampleClass: RCIODirectory.class, RCIOItemExampleBlock: [^(NSURL *url){ [[[NSFileManager alloc] init] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL]; } copy] });
});

SpecEnd
