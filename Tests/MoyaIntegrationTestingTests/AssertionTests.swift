import XCTest
import Moya
@testable import MoyaIntegrationTesting

final class AssertionTests: InterceptingTestCase {
    static var allTests = [
        "test_AssertHeaderEqual_passesForCorrectHeader": test_AssertHeaderEqual_passesForCorrectHeader,
        "test_AssertHeaderEqual_failsForIncorrectHeader": test_AssertHeaderEqual_failsForIncorrectHeader,
        "test_AssertHeaderEqual_failsForNonExistingHeader": test_AssertHeaderEqual_failsForNonExistingHeader,
        "test_AssertBodyEqual_passesForEqualBody": test_AssertBodyEqual_passesForEqualBody,
        "test_AssertBodyEqual_passesForEqualBodyWithCustomEncoding": test_AssertBodyEqual_passesForEqualBodyWithCustomEncoding,
        "test_AssertBodyEqual_failsForInequalBody": test_AssertBodyEqual_failsForInequalBody,
        "test_AssertBodyEqual_failsForEmptyBody": test_AssertBodyEqual_failsForEmptyBody
    ]

    func test_AssertHeaderEqual_passesForCorrectHeader() {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.setValue("value", forHTTPHeaderField: "key")
        AssertHeaderEqual(request, key: "key", value: "value")
    }

    func test_AssertHeaderEqual_failsForIncorrectHeader() {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.setValue("value", forHTTPHeaderField: "key")

        AssertHeaderEqual(request, key: "key", value: "value")

        let failures = interceptFailures(AssertHeaderEqual(request, key: "key", value: "wrongValue"))
        XCTAssertFalse(failures.isEmpty)
    }

    func test_AssertHeaderEqual_failsForNonExistingHeader() {
        let request = URLRequest(url: URL(string: "https://example.com")!)

        let failures = interceptFailures(AssertHeaderEqual(request, key: "key", value: "value"))
        XCTAssertFalse(failures.isEmpty)
    }

    func test_AssertBodyEqual_passesForEqualBody() {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpBody = "Body".data(using: .utf8)

        AssertBodyEqual(request, "Body")
    }

    func test_AssertBodyEqual_passesForEqualBodyWithCustomEncoding() {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpBody = "家".data(using: .japaneseEUC)

        AssertBodyEqual(request, "家", encoding: .japaneseEUC)
    }

    func test_AssertBodyEqual_failsForInequalBody() {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpBody = "Body".data(using: .utf8)

        let failures = interceptFailures(AssertBodyEqual(request, "WrongBody"))
        XCTAssertFalse(failures.isEmpty)
    }

    func test_AssertBodyEqual_failsForEmptyBody() {
        let request = URLRequest(url: URL(string: "https://example.com")!)

        let failures = interceptFailures(AssertBodyEqual(request, "WrongBody"))
        XCTAssertFalse(failures.isEmpty)
    }
}

