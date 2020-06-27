<p align="center">
  <a href="https://codecov.io/gh/wvteijlingen/moya-integration-testing">
    <img src="https://codecov.io/gh/wvteijlingen/moya-integration-testing/branch/master/graph/badge.svg" />
  </a>
</p>
<p align="center">
    <a href="#usage">Usage</a>
  • <a href="#setup">Setup</a>
  • <a href="#convenience-assertions">Convenience assertions</a>
</p>

# moya-integration-testing

A Moya plugin for easy integration testing of your Moya network requests.

## Usage

For each one of your test cases you can configure which endpoints you expect your code to request. Per endpoint you can specify
the returned HTTP status code and body.

After executing the code you want to test, use the assertion methods on the stubbed endpoints to assert that all they were requested,
and to inspect the actual requests made to them.

```swift
func testFetchPosts() {
    // Configure stubs for each endpoint that your code should request.
    // Here we expect our code to make a GET request to "/posts", with a query parameter named "search".
    // When that endpoint is requested, we respond with a 200 status code and an empty JSON array.
    let postsEndpoint = tester.stub("https://example.com/posts?search=foo", method: "GET", statusCode: 200, body: #"[]"#)

    // Execute the code under test.
    testSubject.fetchPosts(withSearch: "foo")

    // Assert that the endpoint was requested exactly once by your code.
    // The assertWasRequested method will fail the test if the endpoint was not requested.
    postsEndpoint.assertWasRequested(with: { request in
        // Optionally we can use a callback to assert that the request was as expected.
        AssertHeaderEqual(request, "Authorization", "Bearer secret-token")
    })

    // You can also assert that an endpoint was requested multiple times, or not at all:
    stubbedEndpoint.assertWasRequested(count: 2)
    stubbedEndpoint.assertWasNotRequested()
}
```

## Setup

1. Use an instance of `MoyaIntegrationTester` as the last plugin in your `MoyaProvider`.
2. Pass the `endpointClosure` function from the same `MoyaIntegrationTester` instance to the Moya provider.
3. Enable stubbing on the Moya provider.

```swift
import MoyaIntegrationTesting

let tester = MoyaIntegrationTester()
let provider = MoyaProvider(
   endpointClosure: tester.endpointClosure(),
   stubClosure: MoyaProvider.immediatelyStub,
   plugins: [tester]
)
```

If your original Moya setup already uses a custom `EndpointClosure`,
you need to use `tester.endpointClosure(wrapping: yourOriginalClosure)` so that your custom closure is still called.

## Convenience assertions

The package ships with a number of custom assertions that make it easier to check `URLRequest` instances:

```swift
/// Asserts that the given `request` contains an HTTP header with the given `key` and `value`.
/// - Parameters:
///   - request: The request to inspect.
///   - key: The key of the expected HTTP header.
///   - value: The expected value of the HTTP header.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func AssertHeaderEqual(_ request: URLRequest, key: String, value: String)
```

Asserts that the given request contains an HTTP header with the given key and value.

```swift
/// Asserts that the body of the given `request` is equal to the expected body.
/// - Parameters:
///   - request: The request to inspect.
///   - body: The expected HTTP body value.
///   - encoding: The encoding of the body value.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func AssertBodyEqual(_ request: URLRequest, _ body: String, encoding: String.Encoding = .utf8)
```
