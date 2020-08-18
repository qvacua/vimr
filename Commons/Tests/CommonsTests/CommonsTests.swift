import XCTest
@testable import Commons

final class CommonsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Commons().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
