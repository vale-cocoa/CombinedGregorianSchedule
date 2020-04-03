//
//  CombinedScheduleTests
//  CombinatorTests.swift
//  
//  Created by Valeriano Della Longa on 01/04/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import XCTest
import GregorianCommonTimetable
import Schedule
import VDLGCDHelpers
@testable import CombinedGregorianSchedule

final class CombinatorTests: XCTestCase
{
    let refDate = Date(timeIntervalSinceReferenceDate: 0)
    
    let mockAsyncGeneratorGeneratingErrorResult: Schedule.AsyncGenerator = { _, queue, completion in
        let result: Result<[DateInterval], Swift.Error> = .failure(ConcurrentResultsGeneratorError.someIterationsNotPerformed)
        dispatchResultCompletion(result: result, queue: queue,completion: completion)
    }
    
    // MARK: - Tests
    // MARK: - Codable & WebAPICodingOptions
    func test_codable()
    {
        // given
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // when
        for combinator in Combinator.allCases {
            do {
                let data = try encoder.encode(combinator)
                let decoded = try decoder.decode(Combinator.self, from: data)
                // then
                XCTAssertEqual(decoded, combinator)
            } catch {
                XCTFail("Error while encoding/decoding: \(error)")
            }
        }
    }
    
    func test_webAPI() {
        // given
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // when
        encoder.setWebAPI(version: .v1)
        decoder.setWebAPI(version: .v1)
        for combinator in Combinator.allCases {
            do {
                let data = try encoder.encode(combinator)
                let decoded = try decoder.decode(Combinator.self, from: data)
                // then
                XCTAssertEqual(decoded, combinator)
            } catch {
                XCTFail("Not conforming to WEBAPICodingOptions. Error: \(error)")
            }
        }
    }
    
    // MARK: - refine operator for Generator
    func test_refineOperator_whenBothGeneratorsAreEmpty_returnsEmptyGenerator()
    {
        // given
        let lhs = emptyGenerator
        let rhs = emptyGenerator
        
        // when
        let result = lhs >>> rhs
        
        // then
        XCTAssertTrue(isEmptyGenerator(result))
    }
    
    func test_refineOperator_whenLhsIsEmptyGenerator_returnsEmptyGenerator()
    {
        // given
        let lhs = emptyGenerator
        let rhs = GregorianCommonTimetable(GregorianWeekdays.saturday).generator
        
        // when
        let result = lhs >>> rhs
        
        // then
        XCTAssertTrue(isEmptyGenerator(result))
    }
    
    func test_refineOperator_whenLhsIsNotEmptyRhsIsEmpty_returnsLhs()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianWeekdays.saturday).generator
        let rhs = emptyGenerator
        
        // when
        let result = lhs >>> rhs
        
        // then
        XCTAssertFalse(isEmptyGenerator(result))
        let end = Calendar.gregorianCalendar.date(byAdding: .year, value: 1, to: refDate)!
        var date = refDate
        while date <= end {
            XCTAssertEqual(lhs(date, .on), result(date, .on))
            XCTAssertEqual(lhs(date, .firstAfter), result(date, .firstAfter))
            XCTAssertEqual(lhs(date, .firstBefore), result(date, .firstBefore))
            date = Calendar.gregorianCalendar.date(byAdding: .day, value: 1, to: date)!
        }
    }
    
    func test_refineOperator_whenLhsDoesntFullyContainsAtLeastOneRhsElement_returnsEmptyGenerator()
    {
        // given
        let cases: [(lhs: GregorianCommonTimetable, rhs: GregorianCommonTimetable)] = [
            (GregorianCommonTimetable(GregorianMonths.january), GregorianCommonTimetable(GregorianMonths.february)),
            (GregorianCommonTimetable(GregorianDays.first), GregorianCommonTimetable(GregorianDays.second)),
            (GregorianCommonTimetable(GregorianDays.first), GregorianCommonTimetable(GregorianMonths.january)),
            (GregorianCommonTimetable(GregorianWeekdays.monday), GregorianCommonTimetable(GregorianWeekdays.tuesday)),
            (GregorianCommonTimetable(GregorianWeekdays.monday), GregorianCommonTimetable(GregorianMonths.january)),
            (GregorianCommonTimetable(GregorianHoursOfDay.am12), GregorianCommonTimetable(GregorianHoursOfDay.am10)),
            (GregorianCommonTimetable(GregorianHoursOfDay.am12), GregorianCommonTimetable(GregorianMonths.january)),
            (GregorianCommonTimetable(GregorianHoursOfDay.am12), GregorianCommonTimetable(GregorianDays.first)),
            (GregorianCommonTimetable(GregorianHoursOfDay.am12), GregorianCommonTimetable(GregorianWeekdays.friday)),
        ]
        
        // when
        for when in cases {
            let lhs = when.lhs.generator
            let rhs = when.rhs.generator
            let result = lhs >>> rhs
            
            // then
            XCTAssertTrue(isEmptyGenerator(result))
        }
        
    }
    
    func test_refineOperator_combiningForGettingFeb29THGenerator_returnsNotEmptyGenerator()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.february).generator
        let rhs = GregorianCommonTimetable(GregorianDays.twentyNineth).generator
        
        // when
        let result = lhs >>> rhs
        
        XCTAssertFalse(isEmptyGenerator(result))
    }
    
    func test_refineOperator_whenLhsIsFeb29THGeneratorRhsIsWeekdayGenerator_returnsNotEmptyGenerator()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.february).generator >>> GregorianCommonTimetable(GregorianDays.twentyNineth).generator
        let rhsCases: [GregorianWeekdays] = [
            .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
        ]
        
        // when
        for weekday in rhsCases
        {
            let rhs = GregorianCommonTimetable(weekday).generator
            let result = lhs >>> rhs
            
            // then
            XCTAssertFalse(isEmptyGenerator(result))
        }
    }
    
    func test_refineOperator_whenLhsIsFeb29THWeekdayGeneratorRhsIsHoursGenerator_returnsNotEmptyGenerator()
    {
        // given
        let feb29THGenerator = GregorianCommonTimetable(GregorianMonths.february).generator >>> GregorianCommonTimetable(GregorianDays.twentyNineth).generator
        let lhsCases: [GregorianWeekdays] = [
            .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
        ]
        let rhsCases: [GregorianHoursOfDay] = [.am1, .am2, .am3, .am4, .am5 , .am6, .am7, .am8, .am9, .am10, .am11, .am12, .pm1, .pm2, .pm3, .pm4, .pm5, .pm6, .pm7, .pm8, .pm9, .pm10, .pm11, .pm12]
        
        // when
        for weekday in lhsCases
        {
            let lhs = feb29THGenerator >>> GregorianCommonTimetable(weekday).generator
            for hour in rhsCases {
                let rhs = GregorianCommonTimetable(hour).generator
                let result = lhs >>> rhs
                
                // then
                XCTAssertFalse(isEmptyGenerator(result))
            }
        }
    }
    
    // MARK: - refined Generator
    func test_refinedGenerator_on_whenLhsReturnsNil_returnsNil()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january).generator
        let rhs = GregorianCommonTimetable(GregorianDays.first).generator
        let sut = lhs >>> rhs
        
        // when
        let date = Calendar.gregorianCalendar.date(bySetting: .month, value: 2, of: refDate)!
        
        // then
        XCTAssertNil(lhs(date, .on))
        XCTAssertNil(sut(date, .on))
    }
    
    func test_refinedGenerator_on_whenLhsReturnsElementRhsReturnsNil_returnsNil()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january).generator
        let rhs = GregorianCommonTimetable(GregorianDays.first).generator
        let sut = lhs >>> rhs
        
        // when
        let date = Calendar.gregorianCalendar.date(bySetting: .day, value: 2, of: refDate)!
        
        // then
        XCTAssertNil(rhs(date, .on))
        XCTAssertNil(sut(date, .on))
    }
    
    func test_refinedGenerator_on_whenLhsReturnsElementRhsReturnsElementFullyContainedInLhsElement_returnsRhsElement()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january).generator
        let rhs = GregorianCommonTimetable(GregorianDays.first).generator
        let sut = lhs >>> rhs
        
        // when
        let expectectedResult = rhs(refDate, .on)
        let result = sut(refDate, .on)
        
        // then
        XCTAssertNotNil(lhs(refDate, .on))
        XCTAssertNotNil(expectectedResult)
        XCTAssertEqual(result, expectectedResult)
    }
    
    func test_refinedGenerator_firstAfter_whenRhsElementFirstAfterDateContainedInLhsElementOnDate_returnsRhsElementFirstAfterDate()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january).generator
        let days: GregorianDays = [.first, .second]
        let rhs = GregorianCommonTimetable(days).generator
        let sut = lhs >>> rhs
        
        // when
        let expectedResult = rhs(refDate, .firstAfter)
        let result = sut(refDate, .firstAfter)
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_refinedGenerator_firstAfter_whenRhsElementFirstAfterDateNotContainedInLhsElementOnDate_returnsFirstRhsElementFullyContainedInLhsElementAfterDate()
    {
        // given
        let months: GregorianMonths = [.february, .march]
        let lhs = GregorianCommonTimetable(months).generator
        let days: GregorianDays = [.twentyNineth, .thirtieth]
        let rhs = GregorianCommonTimetable(days).generator
        let sut = lhs >>> rhs
        
        // when
        let dc = DateComponents(year: 2001, month: 3, day: 29)
        let start = Calendar.gregorianCalendar.date(from: dc)!
        let expectedResult = Calendar.gregorianCalendar.dateInterval(of: .day, for: start)!
        let result = sut(refDate, .firstAfter)
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_refinedGenerator_firstBefore_whenRhsElementFirstBeforeDateContainedInLhsElementOnDate_returnsRhsElementFirstBeforeDate()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january).generator
        let days: GregorianDays = [.first, .second]
        let rhs = GregorianCommonTimetable(days).generator
        let sut = lhs >>> rhs
        
        // when
        let date = Calendar.gregorianCalendar.date(bySetting: .day, value: 2, of: refDate)!
        let expectedResult = rhs(date, .firstBefore)
        let result = sut(date, .firstBefore)
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_refinedGenerator_firstBefore_whenRhsFirstBeforeElementNotContainedInLhsOnDateElement_returnsFirstRhsElementFullyContainedInLhsElementBeforeDate()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january).generator
        let rhs = GregorianCommonTimetable(GregorianDays.first).generator
        let sut = lhs >>> rhs
        
        // when
        let start = Calendar.gregorianCalendar.date(byAdding: .year, value: -1, to: refDate)!
        let expectedResult = Calendar.gregorianCalendar.dateInterval(of: .day, for: start)!
        let result = sut(refDate, .firstBefore)
        
        // then
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - refined AsyncGenerator
    func test_refinedAsyncGenerator_completionExecutes() {
        // given
        let lhs = emptyAsyncGenerator
        let rhs = emptyAsyncGenerator
        let sut = lhs >>> rhs
        let exp = expectation(description: "completion executes")
        var completionExecuted = false
        let dateInterval = DateInterval(start: .distantPast, end: .distantFuture)
        
        // when
        sut(dateInterval, nil, {_ in
            completionExecuted = true
            exp.fulfill()
        })
        
        // then
        wait(for: [exp], timeout: 0.2)
        XCTAssertTrue(completionExecuted)
    }
    
    func test_refinedAsyncGenerator_whenQueueIsNotNil_completionExecutesOnGivenQueue()
    {
        // given
        let lhs = emptyAsyncGenerator
        let rhs = emptyAsyncGenerator
        let sut = lhs >>> rhs
        let exp = expectation(description: "completion executes")
        var thread: Thread!
        let dateInterval = DateInterval(start: .distantPast, end: .distantFuture)
        
        // when
        sut(dateInterval, .main, {_ in
            thread = Thread.current
            exp.fulfill()
        })
        
        // then
        wait(for: [exp], timeout: 0.2)
        XCTAssertEqual(thread, .main)
    }
    
    func test_refinedAsyncGenerator_whenLhsProducesFailureResult_producesSameFailureResult()
    {
        // given
        let lhs = mockAsyncGeneratorGeneratingErrorResult
        let rhs = emptyAsyncGenerator
        let sut = lhs >>> rhs
        let exp = expectation(description: "completion executes")
        let dateInterval = DateInterval(start: .distantPast, end: .distantFuture)
        var result: Result<[DateInterval], Swift.Error>!
        let expectedErrorResult = ConcurrentResultsGeneratorError.someIterationsNotPerformed as NSError
        
        // when
        sut(dateInterval, nil, { sutResult in
            result = sutResult
            exp.fulfill()
        })
        
        // then
        wait(for: [exp], timeout: 0.2)
        switch result {
        case .failure(let resultError as NSError):
            XCTAssertEqual(resultError.domain, expectedErrorResult.domain)
            XCTAssertEqual(resultError.code, expectedErrorResult.code)
        default:
            XCTFail("Async generator didn't produce .failure result")
        }
        
    }
    
    func test_refinedAsyncGenerator_whenLhsProducesSuccessResultEmpty_producesSuccessResultEmpty()
    {
        // given
        let lhs = emptyAsyncGenerator
        let rhs = GregorianCommonTimetable(GregorianHoursOfDay.am).asyncGenerator
        let sut = lhs >>> rhs
        let exp = expectation(description: "completion executes")
        let dateInterval = DateInterval(start: .distantPast, end: .distantFuture)
        var result: Result<[DateInterval], Swift.Error>!
        
        // when
        sut(dateInterval, nil, { sutResult in
            result = sutResult
            exp.fulfill()
        })
        
        // then
        wait(for: [exp], timeout: 0.2)
        switch result {
        case .success(let resultElements):
            XCTAssertTrue(resultElements.isEmpty)
        default:
            XCTFail("Async generator produces .failure result")
        }
    }
    
    func test_refinedAsyncGenerator_whenLhsProducesResultWithElementsAndRhsProducesFailure_producesFailureWithExpectedError()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianHoursOfDay.am).asyncGenerator
        let rhs = mockAsyncGeneratorGeneratingErrorResult
        let sut = lhs >>> rhs
        let exp = expectation(description: "completion executes")
        let dateInterval = Calendar.gregorianCalendar.dateInterval(of: .day, for: refDate)!
        var result: Result<[DateInterval], Swift.Error>!
        let expectedErrorResult = ConcurrentResultsGeneratorError.iterationsFailures([]) as NSError
        
        // when
        sut(dateInterval, nil, { sutResult in
            result = sutResult
            exp.fulfill()
        })
        
        // then
        wait(for: [exp], timeout: 0.2)
        switch result {
        case .failure(let resultError as NSError):
            XCTAssertEqual(resultError.domain, expectedErrorResult.domain)
            XCTAssertEqual(resultError.code, expectedErrorResult.code)
        default:
            XCTFail("Async generator didn't produce .failure result")
        }
    }
    
    func test_refinedAsyncGenerator_whenLhsProducesSuccessResultWithElementsAndRhsProducesSuccessResultEmpty_producesSuccessResultEmpty()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianHoursOfDay.am).asyncGenerator
        let rhs = emptyAsyncGenerator
        let sut = lhs >>> rhs
        let exp = expectation(description: "completion executes")
        let dateInterval = Calendar.gregorianCalendar.dateInterval(of: .day, for: refDate)!
        var result: Result<[DateInterval], Swift.Error>!
        
        // when
        sut(dateInterval, nil, { sutResult in
            result = sutResult
            exp.fulfill()
        })
        
        // then
        wait(for: [exp], timeout: 0.2)
        switch result {
            case .success(let resultElements):
                XCTAssertTrue(resultElements.isEmpty)
            default:
                XCTFail("Async generator produces .failure result")
        }
    }
    
    func test_refinedAsyncGenerator_whenLhsProducesSuccessResultWithElementsAndRhsProducesSuccessWithElements_producesSuccessWithRhsElements()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.firstQuarter).asyncGenerator
        let rhs = GregorianCommonTimetable(GregorianWeekdays.weekend).asyncGenerator
        let sut = lhs >>> rhs
        let dateInterval = Calendar.gregorianCalendar.dateInterval(of: .year, for: refDate)!
        var expectedResult: [DateInterval]!
        let exp1 = expectation(description: "rhs completion completes")
        let exp2 = expectation(description: "sut completion completes")
        let rhsDateInterval = Calendar.gregorianCalendar.dateInterval(of: .quarter, for: refDate)!
        rhs(rhsDateInterval, .main, { rhsResult in
            if case .success(let elements) = rhsResult {
                expectedResult = elements
            }
            exp1.fulfill()
        })
        
        // when
        var result: [DateInterval]!
        sut(dateInterval, .main, { sutResult in
            if case .success(let elements) = sutResult {
                result = elements
            }
            exp2.fulfill()
        })
        
        // then
        wait(for: [exp1, exp2], timeout: 1.0)
        XCTAssertEqual(result, expectedResult)
    }
    
    static var allTests = [
        ("test_refineOperator_whenBothGeneratorsAreEmpty_returnsEmptyGenerator", test_refineOperator_whenBothGeneratorsAreEmpty_returnsEmptyGenerator),
        ("test_refineOperator_whenLhsIsEmptyGenerator_returnsEmptyGenerator",
        test_refineOperator_whenLhsIsEmptyGenerator_returnsEmptyGenerator),
        ("test_refineOperator_whenLhsIsNotEmptyRhsIsEmpty_returnsLhs", test_refineOperator_whenLhsIsNotEmptyRhsIsEmpty_returnsLhs),
        ("test_refineOperator_whenLhsDoesntFullyContainsAtLeastOneRhsElement_returnsEmptyGenerator", test_refineOperator_whenLhsDoesntFullyContainsAtLeastOneRhsElement_returnsEmptyGenerator),
        ("test_refineOperator_whenLhsDoesntFullyContainsAtLeastOneRhsElement_returnsEmptyGenerator", test_refineOperator_whenLhsDoesntFullyContainsAtLeastOneRhsElement_returnsEmptyGenerator),
        ("test_refineOperator_combiningForGettingFeb29THGenerator_returnsNotEmptyGenerator", test_refineOperator_combiningForGettingFeb29THGenerator_returnsNotEmptyGenerator),
        ("test_refineOperator_combiningForGettingFeb29THGenerator_returnsNotEmptyGenerator", test_refineOperator_combiningForGettingFeb29THGenerator_returnsNotEmptyGenerator),
        ("test_refineOperator_whenLhsIsFeb29THGeneratorRhsIsWeekdayGenerator_returnsNotEmptyGenerator", test_refineOperator_whenLhsIsFeb29THGeneratorRhsIsWeekdayGenerator_returnsNotEmptyGenerator),
        ("test_refineOperator_whenLhsIsFeb29THWeekdayGeneratorRhsIsHoursGenerator_returnsNotEmptyGenerator", test_refineOperator_whenLhsIsFeb29THWeekdayGeneratorRhsIsHoursGenerator_returnsNotEmptyGenerator),
        ("test_refinedGenerator_on_whenLhsReturnsNil_returnsNil", test_refinedGenerator_on_whenLhsReturnsNil_returnsNil),
        ("test_refinedGenerator_on_whenLhsReturnsElementRhsReturnsNil_returnsNil", test_refinedGenerator_on_whenLhsReturnsElementRhsReturnsNil_returnsNil),
        ("test_refinedGenerator_on_whenLhsReturnsElementRhsReturnsElementFullyContainedInLhsElement_returnsRhsElement", test_refinedGenerator_on_whenLhsReturnsElementRhsReturnsElementFullyContainedInLhsElement_returnsRhsElement),
        ("test_refinedGenerator_firstAfter_whenRhsElementFirstAfterDateContainedInLhsElementOnDate_returnsRhsElementFirstAfterDate", test_refinedGenerator_firstAfter_whenRhsElementFirstAfterDateContainedInLhsElementOnDate_returnsRhsElementFirstAfterDate),
        ("test_refinedGenerator_firstAfter_whenRhsElementFirstAfterDateNotContainedInLhsElementOnDate_returnsFirstRhsElementFullyContainedInLhsElementAfterDate", test_refinedGenerator_firstAfter_whenRhsElementFirstAfterDateNotContainedInLhsElementOnDate_returnsFirstRhsElementFullyContainedInLhsElementAfterDate),
        ("test_refinedGenerator_firstBefore_whenRhsElementFirstBeforeDateContainedInLhsElementOnDate_returnsRhsElementFirstBeforeDate", test_refinedGenerator_firstBefore_whenRhsElementFirstBeforeDateContainedInLhsElementOnDate_returnsRhsElementFirstBeforeDate),
        ("test_refinedGenerator_firstBefore_whenRhsFirstBeforeElementNotContainedInLhsOnDateElement_returnsFirstRhsElementFullyContainedInLhsElementBeforeDate", test_refinedGenerator_firstBefore_whenRhsFirstBeforeElementNotContainedInLhsOnDateElement_returnsFirstRhsElementFullyContainedInLhsElementBeforeDate),
        ("test_refinedAsyncGenerator_completionExecutes", test_refinedAsyncGenerator_completionExecutes),
        ("test_refinedAsyncGenerator_whenQueueIsNotNil_completionExecutesOnGivenQueue", test_refinedAsyncGenerator_whenQueueIsNotNil_completionExecutesOnGivenQueue),
        ("test_refinedAsyncGenerator_whenLhsProducesFailureResult_producesSameFailureResult", test_refinedAsyncGenerator_whenLhsProducesFailureResult_producesSameFailureResult),
        ("test_refinedAsyncGenerator_whenLhsProducesSuccessResultEmpty_producesSuccessResultEmpty", test_refinedAsyncGenerator_whenLhsProducesSuccessResultEmpty_producesSuccessResultEmpty),
        ("test_refinedAsyncGenerator_whenLhsProducesResultWithElementsAndRhsProducesFailure_producesFailureWithExpectedError", test_refinedAsyncGenerator_whenLhsProducesResultWithElementsAndRhsProducesFailure_producesFailureWithExpectedError),
        ("test_refinedAsyncGenerator_whenLhsProducesSuccessResultWithElementsAndRhsProducesSuccessResultEmpty_producesSuccessResultEmpty", test_refinedAsyncGenerator_whenLhsProducesSuccessResultWithElementsAndRhsProducesSuccessResultEmpty_producesSuccessResultEmpty),
        
    ]
}


