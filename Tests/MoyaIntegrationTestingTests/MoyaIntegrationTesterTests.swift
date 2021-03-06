import XCTest
import Moya
@testable import MoyaIntegrationTesting

final class MoyaIntegrationTesterTests: InterceptingTestCase {
    static var allTests = [
        "test_willSend_matchesCorrectEndpoint": test_willSend_matchesCorrectEndpoint,
        "test_willSend_doesNotMatchOtherEndpoints": test_willSend_doesNotMatchOtherEndpoints,
        "test_endpointClosure_returnsSampleResponse": test_endpointClosure_returnsSampleResponse,
        "test_willSend_assertsFailureOnNonStubbedRequest": test_willSend_assertsFailureOnNonStubbedRequest,
        "test_endpointClosure_returnsNetworkError": test_endpointClosure_returnsNetworkError
    ]
    
    private var tester: MoyaIntegrationTester!
    private var endpointClosure: MoyaProvider<MoyaTarget>.EndpointClosure!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tester = MoyaIntegrationTester()
        endpointClosure = tester.endpointClosure()
    }

    // MARK: - willSend

    func test_willSend_matchesCorrectEndpoint() throws {
        let matchingEndpoint = try tester.stub(
            "https://example.com/users",
            method: "GET",
            statusCode: 200
        )

        let target = MoyaTarget(
            baseURL: URL(string: "https://example.com")!,
            path: "users",
            method: .get
        )

        tester.willSend(target.moyaRequest, target: target)

        XCTAssertTrue(matchingEndpoint.recordedRequests.contains(target.request))

        matchingEndpoint.assertWasRequested { request in
            XCTAssertEqual(request, target.request)
        }

        matchingEndpoint.assertWasRequested(count: 1)

        let failures = interceptFailures(matchingEndpoint.assertWasNotRequested())
        XCTAssertFalse(failures.isEmpty)
    }

    func test_willSend_doesNotMatchOtherEndpoints() throws {
        // Need to stub this to prevent `willSend` from failing on an unexpected endpoint.
        try tester.stub(
            "https://example.com/users",
            method: "GET",
            statusCode: 200
        )

        let nonMatchingEndpoints: [EndpointStub] = [
            try tester.stub("https://example.com/users", method: "POST", statusCode: 200),
            try tester.stub("http://example.com/users", method: "GET", statusCode: 200),
            try tester.stub("http://example.com/users.json", method: "GET", statusCode: 200),
            try tester.stub("https://example.com/users/me", method: "GET", statusCode: 200),
            try tester.stub("https://example.com/users?foo=bar", method: "GET", statusCode: 200),
            try tester.stub("https://example.com/users#foo", method: "GET", statusCode: 200),
            try tester.stub("https://example.com:1234/users", method: "GET", statusCode: 200),
            try tester.stub("https://user@example.com/users", method: "GET", statusCode: 200)
        ]

        let target = MoyaTarget(
            baseURL: URL(string: "https://example.com")!,
            path: "users",
            method: .get
        )

        tester.willSend(target.moyaRequest, target: target)

        for endpoint in nonMatchingEndpoints {
            XCTAssertFalse(endpoint.recordedRequests.contains(target.request))
            endpoint.assertWasNotRequested()

            var failures = interceptFailures(endpoint.assertWasRequested())
            XCTAssertFalse(failures.isEmpty)

            failures = interceptFailures(endpoint.assertWasRequested(count: 1))
            XCTAssertFalse(failures.isEmpty)
        }
    }

    func test_willSend_assertsFailureOnNonStubbedRequest() throws {
        let target = MoyaTarget(
           baseURL: URL(string: "https://example.com")!,
           path: "endpointThatIsNotStubbed",
           method: .get
        )

        let failures = interceptFailures(tester.willSend(target.moyaRequest, target: target))
        XCTAssertEqual(failures[0], "Unexpected request for GET https://example.com/endpointThatIsNotStubbed")
    }

    // MARK: - endpointClosure

    func test_endpointClosure_returnsSampleResponse() throws {
        try tester.stub(
            "https://example.com/users",
            method: "GET",
            statusCode: 200,
            body: "Response body"
        )

        let target = MoyaTarget(
           baseURL: URL(string: "https://example.com")!,
           path: "users",
           method: .get
        )

        let response = endpointClosure(target).sampleResponseClosure()

        switch response {
        case .networkResponse(let statusCode, let data):
            XCTAssertEqual(statusCode, 200)
            XCTAssertEqual(data, "Response body".data(using: .utf8))
        default:
            XCTFail()
        }
    }

    func test_endpointClosure_returnsNetworkError() throws {
        let simulatedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: nil)

        try tester.stub("https://example.com/users", method: "GET") { _ in
            .networkError(simulatedError)
        }

        let target = MoyaTarget(
           baseURL: URL(string: "https://example.com")!,
           path: "users",
           method: .get
        )

        let response = endpointClosure(target).sampleResponseClosure()

        switch response {
        case .networkError(let error):
            XCTAssertEqual(error, simulatedError)
        default:
            XCTFail()
        }
    }


    // MARK: - stub

    func test_stub_throwsErrorOnDuplicateStubs() throws {
        try tester.stub("https://example.com/foo", method: "GET", statusCode: 200)

        XCTAssertThrowsError(try tester.stub(
            "https://example.com/foo",
            method: "GET",
            statusCode: 200
        )) { error in
            switch error {
            case MoyaIntegrationTesting.Error.endpointAlreadyStubbed: ()
            default:
                XCTFail("Expected error to be .endpointAlreadyStubbed")
            }
        }
    }

    func test_stub_throwsErrorOnInvalidURL() {
        XCTAssertThrowsError(try tester.stub(
            "   ",
            method: "GET",
            statusCode: 200
        )) { error in
            switch error {
            case MoyaIntegrationTesting.Error.invalidEndpointURL: ()
            default:
                XCTFail("Expected error to be .invalidEndpointURL")
            }
        }
    }

    func test_stub_throwsErrorOnInvalidBody() {
        XCTAssertThrowsError(try tester.stub(
            "https://example.com/foo",
            method: "GET",
            statusCode: 200,
            body: "Süßigkeiten",
            encoding: .ascii
        )) { error in
            switch error {
            case MoyaIntegrationTesting.Error.invalidBody: ()
            default:
                XCTFail("Expected error to be .invalidEndpointURL")
            }
        }
    }
}
