/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

@class XCAccessibilityElement;
@class XCElementSnapshot;

NS_ASSUME_NONNULL_BEGIN

@interface XCUIApplication (FBHelpers)

/**
 Deactivates application for given time

 @param duration amount of time application should deactivated
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_deactivateWithDuration:(NSTimeInterval)duration error:(NSError **)error;

/**
 Return application elements tree in form of nested dictionaries
 */
- (NSDictionary *)fb_tree;

/**
 Return application elements accessibility tree in form of nested dictionaries
 */
- (NSDictionary *)fb_accessibilityTree;

/**
 Override the accessibility element to be returned for the application. This is
 required to bypass some state tracking that doesn't work properly when the iOS
 11 version of XCTest is used against an iOS 10 device and an application other
 than the original launched app or springboard is in the foreground. XCTest ends
 up creating an XCUIApplication with a generated bundle ID and gets into a
 confused state, which causes queries to fail. By overriding the accessibility
 element we short circuit the application state tracking behavior and force the
 accessibility tree to actually be queried.
 */
- (void)fb_overrideAccessibilityElement:(XCAccessibilityElement *)element;

/**
 Override the running status for an application. See
 fb_overrideAccessibilityElement for details on why you might do this.
 */
- (void)fb_overrideRunning:(BOOL)running;

@end

NS_ASSUME_NONNULL_END
