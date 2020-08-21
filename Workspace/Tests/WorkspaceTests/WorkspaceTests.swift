import XCTest
@testable import Workspace

final class WorkspaceTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Workspace().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
