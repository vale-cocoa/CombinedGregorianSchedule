//
//  CombinedScheduleTests
//  CombinedScheduleTests.swift
//
//  Created by Valeriano Della Longa on 28/03/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import XCTest
import GregorianCommonTimetable
import Schedule
@testable import CombinedGregorianSchedule

final class CombinedGregorianScheduleTests: XCTestCase {
    func test_init_whenEvaluatedOnTokensThrows_throws() {
        // given
        // when
        let tokens: [CombinedGregorianSchedule.Token] = [.binaryOperator(.refine), .operand(.gregorianCommonTimetable(GregorianCommonTimetable(GregorianHoursOfDay.am1)))]
        
        // then
        XCTAssertThrowsError(try CombinedGregorianSchedule(tokens: tokens))
    }
    
    func test_init_whenTokensIsEmpty_doesntThrow() {
        // given
        // when
        // then
        XCTAssertNoThrow(try CombinedGregorianSchedule(tokens: []))
    }

    func test_init_whenEvaluatedOnNotEmptyTokensDoesntThrow_doesntThrow()
    {
        // given
        // when
        let tokens: [CombinedGregorianSchedule.Token] = [.operand(.gregorianCommonTimetable(GregorianCommonTimetable(GregorianMonths.january))), .operand(.gregorianCommonTimetable(GregorianCommonTimetable(GregorianDays.first))), .binaryOperator(.refine)]
        
        // then
        XCTAssertNoThrow(try CombinedGregorianSchedule(tokens: tokens))
    }
    
    func test_initRefining_setsTokensAsValidPostixRepresentation()
    {
        // given
        let lhs = GregorianCommonTimetable(GregorianMonths.january)
        let rhs = GregorianCommonTimetable(GregorianDays.first)
        
        // when
        let result = CombinedGregorianSchedule(refining: lhs, by: rhs).tokens
        
        // then
        XCTAssertNotNil(result.validPostfix())
    }
    
    func test_refined_whenRhsIsGregorianCommonTimetable_returnsCombinedGregorianSchedule()
    {
        // given
        let sut = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianMonths.january), by: GregorianCommonTimetable(GregorianDays.first))
        let rhs = GregorianCommonTimetable(GregorianHoursOfDay.am12)
        
        // when
        let result = sut.refined(by: rhs)
        
        // then
        XCTAssertNotNil(result.tokens.validPostfix())
    }
    
    func test_refined_whenRhsIsCombinedGregorianTimetable_returnsCombinedGregorianSchedule()
    {
        // given
        let sut = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianMonths.january), by: GregorianCommonTimetable(GregorianDays.first))
        let rhs = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianWeekdays.friday), by: GregorianCommonTimetable(GregorianHoursOfDay.am12))
        
        // when
        let result = sut.refined(by: rhs)
        
        // then
        XCTAssertNotNil(result.tokens.validPostfix())
    }
    
    static var allTests = [
        ("test_init_whenEvaluatedOnTokensThrows_throws", test_init_whenEvaluatedOnTokensThrows_throws),
        ("test_init_whenTokensIsEmpty_doesntThrow",  test_init_whenTokensIsEmpty_doesntThrow),
    ("test_init_whenEvaluatedOnNotEmptyTokensDoesntThrow_doesntThrow", test_init_whenEvaluatedOnNotEmptyTokensDoesntThrow_doesntThrow),
    ("test_initRefining_setTokensAsValidPostixRepresentation", test_initRefining_setsTokensAsValidPostixRepresentation),
    ("test_refined_whenRhsIsGregorianCommonTimetable_returnsCombinedGregorianSchedule", test_refined_whenRhsIsGregorianCommonTimetable_returnsCombinedGregorianSchedule),
    ("test_refined_whenRhsIsCombinedGregorianTimetable_returnsCombinedGregorianSchedule", test_refined_whenRhsIsCombinedGregorianTimetable_returnsCombinedGregorianSchedule),
    
    ]
}
