/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSimulatorConnection.h"

#import <Cocoa/Cocoa.h>

#import <CoreSimulator/SimDevice.h>
#import <CoreSimulator/SimDeviceType.h>

#import <SimulatorBridge/SimulatorBridge-Protocol.h>
#import <SimulatorBridge/SimulatorBridge.h>

#import <SimulatorKit/SimDeviceFramebufferService.h>

#import "FBFramebuffer.h"
#import "FBProcessFetcher+Simulators.h"
#import "FBSimulator+Helpers.h"
#import "FBSimulator+Private.h"
#import "FBProcessLaunchConfiguration.h"
#import "FBSimulator.h"
#import "FBSimulatorBridge.h"
#import "FBSimulatorError.h"
#import "FBSimulatorEventSink.h"
#import "FBSimulatorHID.h"
#import "FBSimulatorLaunchConfiguration+Helpers.h"
#import "FBSimulatorLaunchConfiguration.h"

@interface FBSimulatorConnection ()

@property (nonatomic, strong, readonly) id<FBSimulatorEventSink> eventSink;
@property (nonatomic, strong, readonly) dispatch_group_t teardownGroup;

@property (nonatomic, strong, readwrite) FBSimulatorBridge *bridge;
@property (nonatomic, strong, readwrite) FBSimulatorHID *hid;

@end

@implementation FBSimulatorConnection

#pragma mark Initializers

- (instancetype)initWithFramebuffer:(nullable FBFramebuffer *)framebuffer hid:(nullable FBSimulatorHID *)hid bridge:(FBSimulatorBridge *)bridge eventSink:(id<FBSimulatorEventSink>)eventSink
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _eventSink = eventSink;
  _teardownGroup = dispatch_group_create();

  _framebuffer = framebuffer;
  _hid = hid;
  _bridge = bridge;

  return self;
}

#pragma mark NSObject

- (NSString *)description
{
  return [NSString stringWithFormat:
    @"Bridge: Framebuffer (%@) | HID %@ | %@",
    self.framebuffer.description,
    self.hid,
    self.bridge
  ];
}

#pragma mark FBJSONSerializable Implementation

- (id)jsonSerializableRepresentation
{
  return @{
    @"framebuffer" : self.framebuffer.jsonSerializableRepresentation ?: NSNull.null,
    @"hid" : self.hid.jsonSerializableRepresentation ?: NSNull.null,
    @"bridge" : self.bridge.jsonSerializableRepresentation ?: NSNull.null,
  };
}

#pragma mark Lifecycle

- (BOOL)terminateWithTimeout:(NSTimeInterval)timeout
{
  NSParameterAssert(NSThread.currentThread.isMainThread);

  // First stop the Framebuffer
  [self.framebuffer stopListeningWithTeardownGroup:self.teardownGroup];

  // Disconnect the HID
  [self.hid disconnect];
  self.hid = nil;

  // Close the connection with the SimulatorBridge and nullify
  [self.bridge disconnect];
  self.bridge = nil;

  // Notify the eventSink
  [self.eventSink connectionDidDisconnect:self expected:YES];

  // Don't wait if there's no timeout
  if (timeout <= 0) {
    return YES;
  }

  int64_t timeoutInt = ((int64_t) timeout) * ((int64_t) NSEC_PER_SEC);
  long status = dispatch_group_wait(self.teardownGroup, dispatch_time(DISPATCH_TIME_NOW, timeoutInt));
  return status == 0l;
}

@end