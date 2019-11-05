import XCTest
@testable import CSServer

final class CSServerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CSServer().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
