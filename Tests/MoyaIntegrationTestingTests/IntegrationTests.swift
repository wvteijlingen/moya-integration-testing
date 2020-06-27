import XCTest
import Moya
@testable import MoyaIntegrationTesting

final class IntegrationTests: XCTestCase {
    static var allTests = [
        "test_integrationWithMoyaProvider": test_integrationWithMoyaProvider,
    ]

    private var tester: MoyaIntegrationTester!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tester = MoyaIntegrationTester()
    }
    
    func test_integrationWithMoyaProvider() throws {
        let provider = MoyaProvider<TestTarget>(
            endpointClosure: tester.endpointClosure,
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
}
