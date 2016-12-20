/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBApplicationDescriptor ;
@class FBApplicationLaunchConfiguration;
@class FBProcessInfo;
@class FBSimulator;

NS_ASSUME_NONNULL_BEGIN

/**
 A Strategy for Launching Applications.
 */
@interface FBApplicationLaunchStrategy : NSObject

/**
 Creates and returns a new Application Launch Strategy.

 @param simulator the Simulator to launch the Application on.
 @param useBridge YES if the SimulatorBridge should be used, NO otherwise.
 @return a new Application Launch Strategy.
 */
+ (instancetype)withSimulator:(FBSimulator *)simulator useBridge:(BOOL)useBridge;

/**
 Creates and returns a new Application Launch Strategy.
 Uses the default of CoreSimulator to launch the Application

 @param simulator the Simulator to launch the Application on.
 @return a new Application Launch Strategy.
 */
+ (instancetype)withSimulator:(FBSimulator *)simulator;

/**
 Launches and returns the process info for the launched application.

 @param appLaunch the Application Configuration to Launch.
 @param error an error out for any error that occurs.
 @return a Process Info if the Application was launched, nil otherwise.
 */
- (nullable FBProcessInfo *)launchApplication:(FBApplicationLaunchConfiguration *)appLaunch error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
