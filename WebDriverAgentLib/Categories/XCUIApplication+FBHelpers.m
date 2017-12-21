/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <objc/runtime.h>

#import "XCUIApplication+FBHelpers.h"

#import "FBSpringboardApplication.h"
#import "XCAccessibilityElement.h"
#import "XCElementSnapshot.h"
#import "FBElementTypeTransformer.h"
#import "FBMacros.h"
#import "FBXCodeCompatibility.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIDevice+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

const static NSTimeInterval FBMinimumAppSwitchWait = 3.0;
static int associatedAccessibilityElement;
static int associatedRunning;

@implementation XCUIApplication (FBHelpers)

- (BOOL)fb_deactivateWithDuration:(NSTimeInterval)duration error:(NSError **)error
{
  NSString *applicationIdentifier = self.label;
  if(![[XCUIDevice sharedDevice] fb_goToHomescreenWithError:error]) {
    return NO;
  }
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:MAX(duration, FBMinimumAppSwitchWait)]];
  if (self.class.fb_isActivateSupported) {
    [self fb_activate];
    return YES;
  }
  return [[FBSpringboardApplication fb_springboard] fb_tapApplicationWithIdentifier:applicationIdentifier error:error];
}

- (NSDictionary *)fb_tree
{
  [self fb_waitUntilSnapshotIsStable];
  return [self.class dictionaryForElement:self.fb_lastSnapshot];
}

- (NSDictionary *)fb_accessibilityTree
{
  [self fb_waitUntilSnapshotIsStable];
  // We ignore all elements except for the main window for accessibility tree
  return [self.class accessibilityInfoForElement:self.fb_lastSnapshot];
}

- (XCAccessibilityElement *)fb_swizzledAccessibilityElement
{
  XCAccessibilityElement *element = objc_getAssociatedObject(
    self, &associatedAccessibilityElement);

  if (element) {
    return element;
  }

  return [self fb_swizzledAccessibilityElement];
}

- (void)fb_overrideAccessibilityElement:(XCAccessibilityElement *)element
{
  static dispatch_once_t swizzleToken;

  dispatch_once(&swizzleToken, ^{
    Class klass = [XCUIApplication class];
    Method realAccessibilityElement = class_getInstanceMethod(
      klass, @selector(accessibilityElement));
    Method swizzledAccessibilityElement = class_getInstanceMethod(
      klass, @selector(fb_swizzledAccessibilityElement));

    method_exchangeImplementations(
      realAccessibilityElement, swizzledAccessibilityElement);
  });

  objc_setAssociatedObject(
    self, &associatedAccessibilityElement, element, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)fb_swizzledRunning
{
  NSNumber *value = objc_getAssociatedObject(self, &associatedRunning);

  if (value) {
    return [value boolValue];
  }

  return [self fb_swizzledRunning];
}

- (void)fb_overrideRunning:(BOOL)running
{
  static dispatch_once_t swizzleToken;

  dispatch_once(&swizzleToken, ^{
    Class klass = [XCUIApplication class];
    Method realRunning = class_getInstanceMethod(
      klass, @selector(running));
    Method swizzledRunning = class_getInstanceMethod(
      klass, @selector(fb_swizzledRunning));

    method_exchangeImplementations(
      realRunning, swizzledRunning);
  });

  objc_setAssociatedObject(
    self, &associatedRunning, @(running), OBJC_ASSOCIATION_RETAIN);
}

+ (NSDictionary *)dictionaryForElement:(XCElementSnapshot *)snapshot
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
  info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
  info[@"name"] = FBValueOrNull(snapshot.wdName);
  info[@"value"] = FBValueOrNull(snapshot.wdValue);
  info[@"label"] = FBValueOrNull(snapshot.wdLabel);
  info[@"rect"] = snapshot.wdRect;
  info[@"frame"] = NSStringFromCGRect(snapshot.wdFrame);
  info[@"isEnabled"] = [@([snapshot isWDEnabled]) stringValue];
  info[@"isVisible"] = [@([snapshot isWDVisible]) stringValue];

  NSArray *childElements = snapshot.children;
  if ([childElements count]) {
    info[@"children"] = [[NSMutableArray alloc] init];
    for (XCElementSnapshot *childSnapshot in childElements) {
      [info[@"children"] addObject:[self dictionaryForElement:childSnapshot]];
    }
  }
  return info;
}

+ (NSDictionary *)accessibilityInfoForElement:(XCElementSnapshot *)snapshot
{
  BOOL isAccessible = [snapshot isWDAccessible];
  BOOL isVisible = [snapshot isWDVisible];

  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

  if (isAccessible) {
    if (isVisible) {
      info[@"value"] = FBValueOrNull(snapshot.wdValue);
      info[@"label"] = FBValueOrNull(snapshot.wdLabel);
    }
  } else {
    NSMutableArray *children = [[NSMutableArray alloc] init];
    for (XCElementSnapshot *childSnapshot in snapshot.children) {
      NSDictionary *childInfo = [self accessibilityInfoForElement:childSnapshot];
      if ([childInfo count]) {
        [children addObject: childInfo];
      }
    }
    if ([children count]) {
      info[@"children"] = [children copy];
    }
  }
  if ([info count]) {
    info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
    info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
    info[@"name"] = FBValueOrNull(snapshot.wdName);
  } else {
    return nil;
  }
  return info;
}

@end
