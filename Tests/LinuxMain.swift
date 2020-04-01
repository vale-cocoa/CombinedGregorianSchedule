import XCTest

import CombinedGregorianScheduleTests

var tests = [XCTestCaseEntry]()
tests += CombinedGregorianSchedule.allTests()
tests += CombinatorTests.allTests()

XCTMain(tests)
