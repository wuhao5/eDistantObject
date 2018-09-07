//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include <objc/runtime.h>

#import <XCTest/XCTest.h>

#import "googlemac/iPhone/Shared/Performance/Primes/v2/Collectible/Timer/PRMTimerCollectible.h"
#import "googlemac/iPhone/Shared/Performance/Primes/v2/Primes.h"
#import "/Channel/Sources/EDOSocketChannelPool.h"
#import "/Service/Sources/EDOClientService.h"
#import "/Service/Sources/NSObject+EDOValueObject.h"
#import "/Service/Tests/TestsBundle/EDOTestClassDummy.h"
#import "/Service/Tests/TestsBundle/EDOTestDummy.h"
#import "/Service/Tests/TestsBundle/EDOTestProtocol.h"
#import "/Service/Tests/TestsBundle/EDOTestProtocolInApp.h"
#import "/Service/Tests/TestsBundle/EDOTestProtocolInTest.h"

@interface EDOServicePerformanceTest : XCTestCase

@end

@implementation EDOServicePerformanceTest

- (void)setUp {
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    PRMAddTransmitter([PRMConsoleTransmitter new]);
    PRMAddTransmitter([PRMPerfGateTransmitter new]);
    PRMLaunch();
  });
}

- (void)tearDown {
  [EDOSocketChannelPool.sharedChannelPool removeChannelsWithPort:EDOTEST_APP_SERVICE_PORT];
  [super tearDown];
}

- (XCUIApplication *)launchAppWithPort:(int)port initValue:(int)value {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  app.launchArguments = @[
    @"-servicePort", [NSString stringWithFormat:@"%d", port], @"-dummyInitValue",
    [NSString stringWithFormat:@"%d", value]
  ];
  [app launch];
  return app;
}

- (void)testRootObjectWithPort {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:1];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"GetRootObject");
  [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"GetRootObject");
}

- (void)testIdOutParameter {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:2];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"IDOutParameter");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  EDOTestDummy *dummyOut;
  [remoteDummy voidWithOutObject:&dummyOut];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"IDOutParameter");
}

- (void)testRemoteClassAlloc {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:3];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"RemoteClassAlloc");
  Class remoteClass = EDO_REMOTE_CLASS(EDOTestDummy, EDOTEST_APP_SERVICE_PORT);
  [remoteClass alloc];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"RemoteClassAlloc");
}

- (void)testPassByValue {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:4];
  NSArray *array = @[ @1, @2, @3, @4 ];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"PassByValue");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  [remoteDummy returnSumWithArrayAndProxyCheck:[array passByValue]];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"PassByValue");
}

- (void)testPassByValueOnRemoteObject {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"PassByValueRemoteObject");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  NSArray *array = [remoteDummy returnArray];
  [remoteDummy returnCountWithArray:[array passByValue]];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"PassByValueRemoteObject");
}

- (void)testReturnByValue {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:6];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"ReturnByValue");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  [[remoteDummy returnByValue] returnArray];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"ReturnByValue");
}

- (void)testRemoteExceptionThrow {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:7];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"RemoteExceptionThrown");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertThrows([remoteDummy voidWithId:nil]);
  PRMStop(PRMDeferredCollectibleTypeTimer, @"RemoteExceptionThrown");
}

- (void)testProtocolLoaded {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:8];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"ProtocolLoaded");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  [remoteDummy voidWithProtocol:@protocol(EDOTestProtocol)];
  PRMStop(PRMDeferredCollectibleTypeTimer, @"ProtocolLoaded");
}

- (void)testProtocolNotLoaded {
  [self launchAppWithPort:EDOTEST_APP_SERVICE_PORT initValue:9];
  PRMStart(PRMDeferredCollectibleTypeTimer, @"ProtocolNotLoaded");
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertThrowsSpecificNamed([remoteDummy voidWithProtocol:@protocol(EDOTestProtocolInTest)],
                               NSException, NSInternalInconsistencyException);
  PRMStop(PRMDeferredCollectibleTypeTimer, @"ProtocolNotLoaded");
}

@end
