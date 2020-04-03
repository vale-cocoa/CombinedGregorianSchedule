//
//  CombinedGregorianSchedule
//  CombinedGregorianSchedule.swift
//
//  Created by Valeriano Della Longa on 28/03/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
import VDLBinaryExpressionsAPI
import GregorianCommonTimetable
import Schedule

/// A concrete `Schedule` type consisting of the composition of two or more
///   `GregorianCommonTimetable` instances.
public struct CombinedGregorianSchedule {
    typealias Token = BinaryOperatorExpressionToken<Combinator>
    
    let tokens: [Token]
    
    let evaluated: ScheduleOperand
    
    init(tokens: [Token]) throws {
        self.evaluated = try tokens.evaluated()
        self.tokens = tokens.validPostfix()!
    }
    
    /// Returns a new instance combining the leftmost given `GregorianCommonTimetable`
    ///  via refininig operation by the rightmost one.
    ///
    ///  The leftmost schedule's elements will serve as base, and the elements of the rightmost
    ///   schedule which are fully contained in the base ones are gonna be the elements
    ///   returned by the resulting schedule.
    ///   For example let's think of a monthly based schedule as leftmost operand, and a daily
    ///    based schedule as rightmost one,. The resulting schedule elements will consist in the
    ///    days of the rightmost schdule falling on the months included in the leftmost schedule:
    ///    ```
    ///    let monthsTimetable = CommonGregorianTimetable(GregorianMonths.january)
    ///    let days: GregorianDays = [.first, .second]
    ///    let daysTimetable = CommonGregorianTimetable(days)
    ///    let combined = CombinedGregorianSchedule(refining: monthsTimetable, by: daysTimetable)
    ///    ```
    ///    On the contrary doing:
    ///    ```
    ///    let firstTimetable = CommonGregorianTimetable(GregorianMonths.january)
    ///    let secondTimetable = CommonGregorianTimetable(GregorianMonths.august)
    ///    let combined = CombinedGregorianSchedule(refining: firstTimetable, by: secondTimetable)
    ///    ```
    ///    will produce an empty schedule since the rightmost operand never produces
    ///     elements fully contained in the leftmost ones.
    /// - parameter refining: A `GregorianCommonTimetable` instance used as
    ///  starting point of for the refenining operation.
    /// - parameter by: A `GregorainCommonTimetable` instance used for refining
    ///  another one.
    /// - Returns: A new instance of type `CombinedGregorianSchedule`.
    public init(refining lhs: GregorianCommonTimetable, by rhs: GregorianCommonTimetable)
    {
        let lhsToken: Token = .operand(
            .gregorianCommonTimetable(lhs))
        let rhsToken: Token = .operand(.gregorianCommonTimetable(rhs))
        let refineToken: Token = .binaryOperator(.refine)
        
        let tokens = [lhsToken, rhsToken, refineToken]
        self = try! Self(tokens: tokens)
    }
    
    /// Returns a new `CombinedGregorianSchedule` refining the callee by the given
    ///  `GregorianCommonTimetable` one.
    ///
    /// For example doing:
    /// ```
    /// let monthsTimetable = CommonGregorianTimetable(GregorianMonths.january)
    /// let days: GregorianDays = [.first, .second]
    /// let daysTimetable = CommonGregorianTimetable(days)
    /// let combined = CombinedGregorianSchedule(refining: monthsTimetable, by: daysTimetable)
    /// let hours = GregorianHoursOfDay = [.am10, .pm3]
    /// let hoursTimetable = CommonGregorianTimetable(hours)
    /// let recombined = combined.refined(by: hoursTimetable)
    /// ```
    /// will return a schedule whose elements are hours 10am and 3pm falling on the 1st and 2nd
    ///  days of January.
    /// - Parameter by: A `GregorianCommonTimetable` instance used to refine the
    ///  callee.
    /// - Returns: A new `CombinedGregorianSchedule` consisting on the callee one
    ///  refined by the given `GregorianCommonTimetable`.
    public func refined(by rhs: GregorianCommonTimetable) -> CombinedGregorianSchedule
    {
        let rhsToken: Token = .operand(.gregorianCommonTimetable(rhs))
        let refineToken: Token = .binaryOperator(.refine)
        let tokens = self.tokens + [rhsToken, refineToken]
        
        return try! Self(tokens: tokens)
    }
    
    /// Returns a new `CombinedGregorianSchedule` instance by refining the callee with
    ///  the given `CombinedGregorianSchedule`.
    ///
    /// - Parameter by: An instance of `CombinedGregorianSchedule` type used to
    ///  refine the calee.
    /// - Returns: A new `CombinedGregorianSchedule` consisiting of the callee
    ///  refined by the given one.
    public func refined(by rhs: CombinedGregorianSchedule) -> CombinedGregorianSchedule
    {
        let tokens = try! self.tokens.postfix(by: .refine, with: rhs.tokens)
        
        return try! Self(tokens: tokens)
    }
    
}

// MARK: - Schedule Conformance
extension CombinedGregorianSchedule: Schedule {
    public var isEmpty: Bool {
        
        return evaluated.isEmpty
    }
    
    public func contains(_ date: Date) -> Bool {
        
        return evaluated.generators.generator(date, .on) != nil
    }
    
    public func schedule(matching date: Date, direction: CalendarCalculationMatchingDateDirection) -> Element? {
        
        return evaluated.generators.generator(date, direction)
    }
    
    public func schedule(in dateInterval: DateInterval, queue: DispatchQueue?, then completion: @escaping (Result<[Element], Error>) -> Void) {
        
        self.evaluated.generators.asyncGenerator(dateInterval, queue, completion)
    }
    
}
