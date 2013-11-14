# ReactiveCocoaIO

## Overview

ReactiveCocoaIO is a framework for accessing and manipulating a file system
through signals, based on
[ReactiveCocoa](https://github.com/github/ReactiveCocoa).

It's composed of two main class hierarchies:

* [`RCIOFileManager`](ReactiveCocoaIO/RCIOFileManager.h) exposes asynchronous
reactive interfaces for listing directory contents and managing files and
directories.

* [`RCIOItem`](ReactiveCocoaIO/RCIOItem.h) and its two subclasses
[`RCIOFile`](ReactiveCocoaIO/RCIOFile.h) and
[`RCIODirectory`](ReactiveCocoaIO/RCIODirectory.h) expose methods for creating
files and directories and manipulating their contents and metadata.

## Usage

1. Add ReactiveCocoaIO.xcodeproj and
External/ReactiveCocoa/ReactiveCocoaFramework/ReactiveCocoa.xcodeproj (or your
own ReactiveCocoa project file) to your project or workspace.

2. In your target's link phase add:
  1. ReactiveCocoaIO
  2. ReactiveCocoa
  3. Foundation
  4. CoreServices _(only on OS X)_

3. If you're building an iOS app you might have add the libraries to your
target's dependencies too, Xcode isn't too good at figuring those out.
