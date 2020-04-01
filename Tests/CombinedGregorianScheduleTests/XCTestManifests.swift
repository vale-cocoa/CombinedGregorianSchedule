import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CombinedGregorianSchedule.allTests),
        testCase(CombinatorTests.allTests),
        
    ]
}
#endif
