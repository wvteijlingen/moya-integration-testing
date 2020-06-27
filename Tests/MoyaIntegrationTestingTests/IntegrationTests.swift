import XCTest
import Moya
@testable import MoyaIntegrationTesting

final class IntegrationTests: XCTestCase {
    static var allTests = [
        "test_integration": test_integration,
        "test_integrationWithCustomEndpointClosure": test_integrationWithCustomEndpointClosure,
    ]

    private var tester: MoyaIntegrationTester!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tester = MoyaIntegrationTester()
    }
    
    func test_integration() throws {
        let provider = MoyaProvider<TestTarget>(
            endpointClosure: tester.endpointClosure(),
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: [tester]
        )

        let responseBody = "Response body".data(using: .utf8)!
        let fooEndpoint = try tester.stub(
            "https://example.com/foo",
            method: "GET",
            statusCode: 200,
            body: responseBody
        )

        provider.request(.foo) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.data, responseBody)
            default:
                XCTFail()
            }
        }

        fooEndpoint.assertWasRequested()
    }

    func test_integrationWithCustomEndpointClosure() throws {
        var didCallOriginalEndpointClosure = false

        let originalEndpointClosure: MoyaProvider<TestTarget>.EndpointClosure = { target in
            didCallOriginalEndpointClosure = true

            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            return defaultEndpoint.adding(newHTTPHeaderFields: ["customizedHeader": "value"])
        }

        let provider = MoyaProvider<TestTarget>(
            endpointClosure: tester.endpointClosure(wrapping: originalEndpointClosure),
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: [tester]
        )

        let fooEndpoint = try tester.stub(
            "https://example.com/foo",
            method: "GET",
            statusCode: 200
        )

        provider.request(.foo, completion: { _ in })

        fooEndpoint.assertWasRequested() { request in
            AssertHeaderEqual(request, key: "customizedHeader", value: "value")
        }

        XCTAssertTrue(didCallOriginalEndpointClosure)
    }
}
