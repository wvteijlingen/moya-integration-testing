import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MoyaTestTests.allTests),
        testCase(IntegrationTests.allTests),
        testCase(AssertionTests.allTests)
    ]
}
#endif
