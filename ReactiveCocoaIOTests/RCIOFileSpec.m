//
//  RCIOFileSpec.m
//  ReactiveCocoaIO
//
//  Created by Uri Baghin on 15/01/2013.
//  Copyright (c) 2013 Enthusiastic Code. All rights reserved.
//

#import "RCIOItemExamples.h"

SpecBegin(RCIOFile)

describe(@"RCIOFile", ^{
	itShouldBehaveLike(RCIOItemExamples, @{ RCIOItemExampleClass: RCIOFile.class, RCIOItemExampleBlock: [^(NSURL *url){ [@"" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:NULL]; } copy] });
});

SpecEnd
