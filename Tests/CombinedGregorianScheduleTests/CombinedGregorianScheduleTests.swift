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
    // MARK: - then
    func thenAreEqual(lhs: [CombinedGregorianSchedule.Token], rhs: [CombinedGregorianSchedule.Token])
    {
        XCTAssertEqual(lhs.count, rhs.count)
        for i in 0..<lhs.count {
            let decodedToken = lhs[i]
            let sutToken = rhs[i]
            switch (decodedToken, sutToken) {
            case (.operand(let decodedOperand), .operand(let sutOperand)):
                guard
                    case .gregorianCommonTimetable(let decodedTimetable) = decodedOperand,
                    case .gregorianCommonTimetable(let sutTimetable) = sutOperand
                    else {
                        XCTFail("Not equal: \(decodedOperand) - \(sutOperand)")
                        return
                }
                
                XCTAssertEqual(decodedTimetable.kind, sutTimetable.kind)
                XCTAssertEqual(decodedTimetable.onScheduleValues, sutTimetable.onScheduleValues)
            
            case (.binaryOperator(let decodedOperation), .binaryOperator(let sutOperation)):
                XCTAssertEqual(decodedOperation, sutOperation)
            
            default:
                XCTFail("Not equal: \(decodedToken) - \(sutToken)")
            }
        }
    }
    
    // MARK: - Tests
    // MARK: - init tests
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
    
    // MARK: - refined(by:) tests
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
    
    // MARK: - Codable & WebAPICodingOptions tests
    func test_codable() {
        // given
        let lhs = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianMonths.january), by: GregorianCommonTimetable(GregorianDays.first))
        let rhs = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianWeekdays.friday), by: GregorianCommonTimetable(GregorianHoursOfDay.am12))
        let sut = lhs.refined(by: rhs)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // when
        do {
            let data = try encoder.encode(sut)
            let decoded = try decoder.decode(CombinedGregorianSchedule.self, from: data)
            
            // then
            thenAreEqual(lhs: decoded.tokens, rhs: sut.tokens)
            } catch {
                XCTFail("Error while encoding/decoding: \(error)")
        }
    }
    
    func test_webAPI() {
        // given
        let lhs = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianMonths.january), by: GregorianCommonTimetable(GregorianDays.first))
        let rhs = CombinedGregorianSchedule(refining: GregorianCommonTimetable(GregorianWeekdays.friday), by: GregorianCommonTimetable(GregorianHoursOfDay.am12))
        let sut = lhs.refined(by: rhs)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // when
        encoder.setWebAPI(version: .v1)
        decoder.setWebAPI(version: .v1)
        do {
            let data = try encoder.encode(sut)
            let decoded = try decoder.decode(CombinedGregorianSchedule.self, from: data)
            
            // then
            thenAreEqual(lhs: decoded.tokens, rhs: sut.tokens)
            } catch {
                XCTFail("Not conforming to WEBAPICodingOptions. Error: \(error)")
        }
    }
    
    static var allTests = [
        ("test_init_whenEvaluatedOnTokensThrows_throws", test_init_whenEvaluatedOnTokensThrows_throws),
        ("test_init_whenTokensIsEmpty_doesntThrow",  test_init_whenTokensIsEmpty_doesntThrow),
        ("test_init_whenEvaluatedOnNotEmptyTokensDoesntThrow_doesntThrow", test_init_whenEvaluatedOnNotEmptyTokensDoesntThrow_doesntThrow),
        ("test_initRefining_setTokensAsValidPostixRepresentation", test_initRefining_setsTokensAsValidPostixRepresentation),
        ("test_refined_whenRhsIsGregorianCommonTimetable_returnsCombinedGregorianSchedule", test_refined_whenRhsIsGregorianCommonTimetable_returnsCombinedGregorianSchedule),
        ("test_refined_whenRhsIsCombinedGregorianTimetable_returnsCombinedGregorianSchedule", test_refined_whenRhsIsCombinedGregorianTimetable_returnsCombinedGregorianSchedule),
        ("test_codable", test_codable),
        ("test_webAPI", test_webAPI),
        
    ]
}
