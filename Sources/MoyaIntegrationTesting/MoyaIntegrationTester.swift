import Foundation
import XCTest
import Moya

/// A Moya plugin that can be used to run integration tests for network requests going through Moya.
///
/// # Setup
/// Use an instance of `MoyaIntegrationTester` as the last plugin in your `MoyaProvider`.
/// Use the `endpointClosure` from the same `MoyaTester` instance as the `endpointClosure` of the `MoyaProvider`.
/// You must also enable stubbing on the provider.
///
/// ```
/// let tester = MoyaIntegrationTester()
/// let provider = MoyaProvider(
///    endpointClosure: tester.endpointClosure,
///    stubClosure: MoyaProvider.immediatelyStub,
///    plugins: [tester]
/// )
/// ```
///
/// # Usage
/// First configure your stubbed endpoints and the response the return when requested by your code.
/// Then you execute the code that is under test. Finally you can use the assertion methods on the stubbed endpoints
/// to assert that all they were requested, and to inspect the actual requests made to them.
///
/// ```
/// // Configure stubs for each endpoint that your code should request.
/// let endpoint = responseStubber.stub("https://example.com/posts", method: "GET", statusCode: 200, body: #"[]"#)
///
/// // Execute the code under test.
/// testSubject.fetchPosts()
///
/// // Assert that "https://example.com/posts" was actually requested by your code.
/// endpoint.assertWasRequested(with: { request in
///     // Optionally assert that the request for "/posts" was as expected.
///     AssertHeaderEqual(request, "Authorization", "Bearer secret-token")
/// }
/// ```
public class MoyaIntegrationTester {
    private var endpointStubs: [EndpointStub] = []

    func endpointClosure<T: TargetType>(for target: T) -> Endpoint {
        let urlString = URL(target: target).absoluteString

        guard let stub = stub(for: urlString, httpMethod: target.method.rawValue) else {
            XCTFail("Unexpected request for \(target.method) \(urlString)")
            fatalError()
        }

        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { stub.response },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
       )
    }

    /// Configures a stub response for the given `url`.
    /// - Parameters:
    ///   - url: The url to configure the stub for.
    ///   - method: The HTTP method to configure the stub for.
    ///   - statusCode: The HTTP status code to use for the response.
    ///   - body: The HTTP body to use for the response.
    /// - Throws: MoyaTester.Error
    /// - Returns: A stubbed endpoint.
    func stub(_ url: String, method: String, statusCode: Int, body: Data = Data()) throws -> EndpointStub {
        guard stub(for: url, httpMethod: method) == nil else {
            throw Error.endpointAlreadyStubbed
        }

        let stub = try EndpointStub(
            httpMethod: method,
            url: url,
            response: EndpointSampleResponse.networkResponse(statusCode, body)
        )

        endpointStubs.append(stub)

        return stub
    }

    /// Configures a stub response for the given `url`.
    /// - Parameters:
    ///   - url: The url to configure the stub for.
    ///   - method: The HTTP method to configure the stub for.
    ///   - statusCode: The HTTP status code to use for the response.
    ///   - body: The HTTP body to use for the response.
    ///   - encoding: The encoding to use for the HTTP body. Defaults to utf8.
    /// - Throws: MoyaTester.Error
    /// - Returns: A stubbed endpoint.
    func stub(
        _ url: String,
        method: String,
        statusCode: Int,
        body: String,
        encoding: String.Encoding = .utf8
    ) throws -> EndpointStub {
        guard let bodyData = body.data(using: encoding) else {
            throw Error.invalidBody
        }

        return try stub(url, method: method, statusCode: statusCode, body: bodyData)
    }

    private func stub(for url: String, httpMethod: String) -> EndpointStub? {
        return endpointStubs.first { $0.matches(url: url, httpMethod: httpMethod) }
    }
}

extension MoyaIntegrationTester: PluginType {
    /// Implementation of `Moya.PluginType`. You should not not call this method yourself.
    public func willSend(_ request: RequestType, target: TargetType) {
        guard
            let urlRequest = request.request,
            let url = urlRequest.url,
            let httpMethod = urlRequest.httpMethod,
            let stub = self.stub(for: url.absoluteString, httpMethod: httpMethod)
        else {
            return
        }

        stub.record(request: urlRequest)
    }
}

public class EndpointStub {
    fileprivate let httpMethod: String
    fileprivate let components: URLComponents
    fileprivate let response: EndpointSampleResponse

    /// All requests that are made to this endpoint.
    private(set) var recordedRequests: [URLRequest] = []

    init(httpMethod: String, url: String, response: EndpointSampleResponse) throws {
        guard let components = URLComponents(string: url) else {
            throw Error.invalidEndpointURL
        }

        self.httpMethod = httpMethod.uppercased()
        self.components = components
        self.response = response
    }

    /// Asserts that the endpoint was requested once.
    /// - Parameters:
    ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
    ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
    ///   - inspector: A callback that you can use to inspect the request and assert that it was as expected.
    func assertWasRequested(
        file: StaticString = #file,
        line: UInt = #line,
        with inspector: ((_ request: URLRequest) -> Void)? = nil
    ) {
        if recordedRequests.count != 1 {
            XCTFail(
                "Expected endpoint to be requested 1 time, but it was requested \(recordedRequests.count) times",
                file: file,
                line: line
            )
            return
        }

        inspector?(recordedRequests[0])
    }

    /// Asserts that the endpoint was requested a specific number of times.
    /// - Parameters:
    ///   - count: The expected amount of times the endpoint should have been requested
    ///   - inspector: A callback that you can use to inspect the requests and assert that they were as expected.
    ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
    ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
    func assertWasRequested(
        count: Int,
        file: StaticString = #file,
        line: UInt = #line,
        with inspector: ((_ requests: [URLRequest]) -> Void)? = nil
    ) {
        if recordedRequests.count != count {
            XCTFail(
                "Expected endpoint to be requested \(count) times, but it was requested \(recordedRequests.count) times",
                file: file,
                line: line
            )
        }

        inspector?(recordedRequests)
    }

    /// Asserts that the endpoint was not requested.
    /// - Parameters:
    ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
    ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
    func assertWasNotRequested(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(
            recordedRequests.isEmpty,
            "Expected endpoint to be requested 0 times, but it was requested \(recordedRequests.count) times",
            file: file,
            line: line
        )
    }

    fileprivate func matches(url: String, httpMethod: String) -> Bool {
        guard let url = URL(string: url) else { return false }
        guard let requestComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return false }

        guard httpMethod.uppercased() == self.httpMethod else { return false }
        guard requestComponents.scheme == components.scheme else { return false }
        guard requestComponents.user == components.user else { return false }
        guard requestComponents.host == components.host else { return false }
        guard requestComponents.port == components.port else { return false }
        guard requestComponents.path == components.path else { return false }
        guard requestComponents.fragment == components.fragment else { return false }
        guard Set(requestComponents.queryItems ?? []) == Set(components.queryItems ?? []) else { return false}

        return true
    }

    fileprivate func record(request: URLRequest) {
        recordedRequests.append(request)
    }
}

public enum Error: Swift.Error {
    case endpointAlreadyStubbed
    case invalidEndpointURL
    case invalidBody
}

/// Asserts that the given `request` contains an HTTP header with the given `key` and `value`.
/// - Parameters:
///   - request: The request to inspect.
///   - key: The key of the expected HTTP header.
///   - value: The expected value of the HTTP header.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func AssertHeaderEqual(
    _ request: URLRequest,
    key: String,
    value: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    guard let header = request.allHTTPHeaderFields?.first(where: { $0.key == key }) else {
        XCTFail("Expected header '\(key)' is not present in request", file: file, line: line)
        return
    }

    XCTAssertEqual(header.value, value, file: file, line: line)
}

/// Asserts that the body of the given `request` is equal to the expected body.
/// - Parameters:
///   - request: The request to inspect.
///   - body: The expected HTTP body value.
///   - encoding: The encoding of the body value.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func AssertBodyEqual(
    _ request: URLRequest,
    _ body: String,
    encoding: String.Encoding = .utf8,
    file: StaticString = #file,
    line: UInt = #line
) {
    if let requestBody = request.httpBody {
        XCTAssertEqual(String(data: requestBody, encoding: encoding), body, file: file, line: line)
    } else {
        XCTFail("Request does not contain a body", file: file, line: line)
    }
}
