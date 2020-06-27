import XCTest

import MoyaTestTests

var tests = [XCTestCaseEntry]()
tests += MoyaIntegrationTesterTests.allTests()
tests += IntegrationTests.allTests()
tests += AssertionTests.allTests()
XCTMain(tests)
