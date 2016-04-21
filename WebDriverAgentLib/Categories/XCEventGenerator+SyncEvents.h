/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import <WebDriverAgentLib/XCEventGenerator.h>

@interface XCEventGenerator (SyncEvents)

- (BOOL)fb_syncTapAtPoint:(CGPoint)point orientation:(UIInterfaceOrientation)orientation error:(NSError **)error;

@end