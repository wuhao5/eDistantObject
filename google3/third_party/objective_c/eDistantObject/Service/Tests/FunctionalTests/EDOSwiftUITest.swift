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

import Foundation
import XCTest

import third_party_objective_c_eDistantObject_Service_Service
import third_party_objective_c_eDistantObject_Service_Tests_TestsBundle_TestsBundleHeader
import third_party_objective_c_eDistantObject_Service_Tests_TestsBundle_TestsSwiftProtocol

class EDOSwiftUITest: XCTestCase {
  @discardableResult
  func launchAppWithPort(port : Int, value : Int) -> XCUIApplication {
    let application = XCUIApplication()
    application.launchArguments = [
      "-servicePort", String(format:"%d", port), String("-dummyInitValue"),
      String(format:"%d", value)]
    application.launch()
    return application
  }

  func testRemoteInvocation() {
    launchAppWithPort(port:1234, value:10)
    let service = EDOHostService(port:2234, rootObject:self, queue:DispatchQueue.main)

    let dummyClass = EDOTestClassDummy(value:20)
    let testDummy = unsafeBitCast(dummyClass, to: EDOTestDummyExtension.self)
    let swiftClass = testDummy.returnProtocol()
    XCTAssertEqual(swiftClass.returnString(), "Swift String")

    XCTAssertEqual(swiftClass.returnWithBlock { (str : NSString) in
      XCTAssertEqual(str, "Block")
      return swiftClass
    }, "Swift StringBlock")

    service.invalidate()
  }
}
