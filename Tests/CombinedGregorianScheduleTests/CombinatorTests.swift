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
@testable import CombinedGregorianSchedule

final class CombinatorTests: XCTestCase
{
    let refDate = Date(timeIntervalSinceReferenceDate: 0)
    
    // MARK: - Tests
    // MARK: - refine operator on generator tests
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
    
    // MARK: - tests on generator returned from refine operator
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
    
    func test_refinedOperator_on_whenLhsReturnsElementRhsReturnsNil_returnsNil()
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
    
    func test_refinedOperator_on_whenLhsReturnsElementRhsReturnsElementFullyContainedInLhsElement_returnsRhsElement()
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
        ("test_refinedOperator_on_whenLhsReturnsElementRhsReturnsNil_returnsNil", test_refinedOperator_on_whenLhsReturnsElementRhsReturnsNil_returnsNil),
        ("test_refinedOperator_on_whenLhsReturnsElementRhsReturnsElementFullyContainedInLhsElement_returnsRhsElement", test_refinedOperator_on_whenLhsReturnsElementRhsReturnsElementFullyContainedInLhsElement_returnsRhsElement)
    ]
}
