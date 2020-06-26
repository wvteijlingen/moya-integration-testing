import XCTest
@testable import MoyaIntegrationTesting

final class MoyaIntegrationTesterTests: XCTestCase {
    static var allTests = [
        "testWillSend": testWillSend,
        "testEndpointClosure": testEndpointClosure
    ]
    
    private var tester: MoyaIntegrationTester!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tester = MoyaIntegrationTester()
    }

    func testWillSend() throws {
        let endpointThatShouldBeRequested = try tester.stub("https://example.com/users", method: "GET", statusCode: 200)

        let otherEndpoints: [EndpointStub] = [
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

        XCTAssertTrue(endpointThatShouldBeRequested.recordedRequests.contains(target.request))
        endpointThatShouldBeRequested.assertWasRequested { request in
            XCTAssertEqual(request, target.request)
        }

        for otherEndpoint in otherEndpoints {
            XCTAssertFalse(otherEndpoint.recordedRequests.contains(target.request))
            otherEndpoint.assertWasNotRequested()
        }
    }

    func testEndpointClosure() throws {
        _ = try tester.stub("https://example.com/users", method: "GET", statusCode: 200, body: "response")

        let target = MoyaTarget(
            baseURL: URL(string: "https://example.com")!,
            path: "users",
            method: .get
        )

        let moyaEndpoint = tester.endpointClosure(for: target)

        switch moyaEndpoint.sampleResponseClosure() {
        case .networkResponse(let statusCode, let data):
            XCTAssertEqual(statusCode, 200)
            XCTAssertEqual(data, "response".data(using: .utf8))
        default:
            XCTFail()
        }
    }
}
