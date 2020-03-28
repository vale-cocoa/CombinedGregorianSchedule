import XCTest
@testable import CombinedSchedule

final class CombinedScheduleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CombinedSchedule().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
