import XCTest

/// A test case that can intercept failing assertions and report them.
/// This can be used to test if custom assertions are failing, without them failing the test itself.
class InterceptingTestCase: XCTestCase {
    private var interceptedFailures: [String] = []
    private var isInterceptingFailures: Bool = false

    override func recordFailure(
        withDescription description: String,
        inFile filePath: String,
        atLine lineNumber: Int,
        expected: Bool
    ) {
        if isInterceptingFailures {
            appendInterceptedFailure(withDescription: description)
        } else {
            super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
        }
    }

    private func appendInterceptedFailure(withDescription description: String) {
        if description.hasPrefix("failed - ") {
            interceptedFailures.append(String(description.dropFirst("failed - ".count)))
        } else {
            interceptedFailures.append(description)
        }
    }

    /// Runs the given closure and returns the descriptions of all assertion failures that occured during execution.
    func interceptFailures(_ fn: @autoclosure () -> Void) -> [String] {
        interceptedFailures = []
        isInterceptingFailures = true
        fn()
        isInterceptingFailures = false
        return interceptedFailures
    }
}
