//
//  RCIODirectorySpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 15/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItemExamples.h"

SpecBegin(RCIODirectory)

describe(@"RCIODirectory", ^{
	itShouldBehaveLike(RCIOItemExamples, @{ RCIOItemExampleClass: RCIODirectory.class, RCIOItemExampleBlock: [^(NSURL *url){ [NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL]; } copy] });
});

SpecEnd
