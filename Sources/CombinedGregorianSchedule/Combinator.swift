//
//  CombinedSchedule
//  Combinator.swift
//
//  Created by Valeriano Della Longa on 30/03/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
import Schedule
import GregorianCommonTimetable
import VDLBinaryExpressionsAPI
import VDLGCDHelpers
import VDLCalendarUtilities

enum Combinator: CaseIterable {
    case refine
}

// MARK: - BinaryOperatorProtocol conformance
extension Combinator: BinaryOperatorProtocol {
    
    typealias Operand = ScheduleOperand
    
    var priority: Int {
        switch self {
        case .refine:
            return 100
        }
    }
    
    var associativity: BinaryOperatorAssociativity {
        switch self {
        case .refine:
            return .right
        }
    }
    
    var binaryOperation: (ScheduleOperand, ScheduleOperand) throws -> ScheduleOperand {
        switch self {
        case .refine:
            return _refine(lhs:rhs:)
        }
    }
    
    func _refine(lhs: ScheduleOperand, rhs: ScheduleOperand) -> ScheduleOperand {
        let generator = lhs.generators.generator >>> rhs.generators.generator
        let asyncGenerator = isEmptyGenerator(generator) ? emptyAsyncGenerator : lhs.generators.asyncGenerator >>> rhs.generators.asyncGenerator
        
        return .evaluated(generator, asyncGenerator)
    }
    
}

// MARK: Codable conformance
extension Combinator: Codable {
    enum CodingKeys: String, CodingKey {
        case base
    }
    
    enum Base: String, Codable {
        case refine
        
        init(_ combinator: Combinator)
        {
            switch combinator {
            case .refine:
                self = .refine
            }
        }
        
        var combinator: Combinator {
            switch self {
            case .refine:
                return .refine
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Base(self), forKey: .base)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)
        self = base.combinator
    }
    
}

// MARK: - Functional >>> Operator
precedencegroup RefinePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator >>>: RefinePrecedence

func >>>(lhs: @escaping Schedule.Generator, rhs: @escaping Schedule.Generator) -> Schedule.Generator {
    switch (isEmptyGenerator(lhs), isEmptyGenerator(rhs))
    {
    case (true, true):
        return emptyGenerator
    case (true, false):
        return emptyGenerator
    case (false, true):
        return lhs
    case (false, false):
        break
    }
    
    /*
    RHS is supposed to refine LHS results, hence it should return
    date intervals less than or equal to those returned by LHS, moreover
    RHS' results are supposed to have during one year at least one
     element fully contained in one of LHS' elemnts.
    We can do a preliminary check for this condition.
    */
    
    let durationOfLhsElement = lhs(.distantPast, .firstAfter)?.duration ?? lhs(.distantFuture, .firstBefore)!.duration
    let maxLhsIterations: Int!
    if durationOfLhsElement <= 3600 {
        maxLhsIterations = 24
    } else if durationOfLhsElement <= (3600*24) {
        maxLhsIterations = 31
    } else {
        maxLhsIterations = 12
    }
    
    let refDate = Date(timeIntervalSinceReferenceDate: 0)
    var lhsIterations = 0
    var lhsFullyContainsAtLeastOneRhsElement = false
    var lhsElement: DateInterval? = lhs(refDate, .on) ?? lhs(refDate, .firstAfter)
    MainLoop: while
        lhsIterations <= maxLhsIterations,
        let lhsElementStart = lhsElement?.start
    {
        var rhsElement: DateInterval? = rhs(lhsElementStart, .on) ?? rhs(lhsElementStart, .firstAfter)
        while
            let  rhsCandidate = rhsElement,
            rhsCandidate.start <= lhsElement!.end
        {
            if
                let intersection = lhsElement!.intersection(with: rhsCandidate),
                intersection.duration == rhsCandidate.duration
            {
                lhsFullyContainsAtLeastOneRhsElement = true
                break MainLoop
            }
            rhsElement = rhs(rhsCandidate.start, .firstAfter)
        }
        
        lhsElement = lhs(lhsElementStart, .firstAfter)
        lhsIterations += 1
    }
    
    guard
        lhsFullyContainsAtLeastOneRhsElement == true
        else { return emptyGenerator }
    
    return { date, direction in
        guard
            let lhsDateInterval = lhs(date, direction)
            else { return nil }
        
        switch direction {
        case .on:
            guard
                let rhsDateInterval = rhs(date, .on),
                rhsDateInterval.duration <= lhsDateInterval.duration,
                let intersection = lhsDateInterval.intersection(with: rhsDateInterval),
                intersection.duration == rhsDateInterval.duration
                else { return nil }
            
            return rhsDateInterval
       
        case .firstAfter:
            var newLhsResult: DateInterval? = lhsDateInterval
            var newRhsResult: DateInterval? = rhs(lhsDateInterval.start, .on) ?? rhs(lhsDateInterval.start, .firstAfter)
            var lhsIterations = 0
            while
                lhsIterations <= maxLhsIterations,
                let lhsCandidate = newLhsResult
            {
                while
                    let rhsCandidate = newRhsResult,
                    rhsCandidate.start <= lhsCandidate.end
                {
                    if
                        let intersection = lhsCandidate.intersection(with: rhsCandidate),
                        intersection.duration == rhsCandidate.duration
                    {
                        return intersection
                    }
                    newRhsResult = rhs(rhsCandidate.start, .firstAfter)
                }
                newLhsResult = lhs(lhsCandidate.start, .firstAfter)
                lhsIterations += 1
            }
            
            return nil
        
        case .firstBefore:
            var newLhsResult: DateInterval? = lhsDateInterval
            var newRhsResult: DateInterval? = rhs(lhsDateInterval.end, .on) ?? rhs(lhsDateInterval.end, .firstBefore)
            var lhsIterations = 0
            while
                lhsIterations <= maxLhsIterations,
                let lhsCandidate = newLhsResult
            {
                while
                    let rhsCandidate = newRhsResult,
                    rhsCandidate.start >= lhsCandidate.start
                {
                    if
                        let intersection = lhsCandidate.intersection(with: rhsCandidate),
                        intersection.duration == rhsCandidate.duration
                    {
                        
                        return intersection
                    }
                    newRhsResult = rhs(rhsCandidate.end, .firstBefore)
                }
                newLhsResult = lhs(lhsCandidate.end, .firstBefore)
                lhsIterations += 1
            }
            
            return nil
        }
    }
    
}

func >>>(lhs: @escaping Schedule.AsyncGenerator, rhs: @escaping Schedule.AsyncGenerator) -> Schedule.AsyncGenerator {
    
    return { dateInterval, queue, completion in
        DispatchQueue.global(qos: .userInitiated).async {
            var lhsResult: Result<[DateInterval], Swift.Error>!
            let lhsOperation = DispatchGroup.init()
            lhsOperation.enter()
            lhs(dateInterval, nil, { result in
                lhsResult = result
                lhsOperation.leave()
            })
            lhsOperation.wait()
            
            guard
                case .success(let lhsSchedule) = lhsResult
                else {
                    dispatchResultCompletion(result: lhsResult, queue: queue, completion: completion)
                    return
            }
            
            concurrentResultsGenerator(
                countOfIterations: lhsSchedule.count,
                startingSeed: lhsSchedule,
                iterationSeeder:
                { lhsElements, idx -> DateInterval in
                    return lhsElements[idx]
            },
                iterationGenerator:
                { lhsElement throws -> [DateInterval] in
                    let iterOperation = DispatchGroup()
                    var iterationResult: Result<[DateInterval], Swift.Error>!
                    iterOperation.enter()
                    rhs(lhsElement, nil, { rhsResult in
                        iterationResult = rhsResult
                        iterOperation.leave()
                    })
                    iterOperation.wait()
                    switch iterationResult {
                    case .success(let iterRhsElements):
                        return iterRhsElements
                    case .failure(let error):
                        throw error
                    case .none:
                        throw ConcurrentResultsGeneratorError.someIterationsNotPerformed
                    }
            },
                shouldNotCalculateMoreOnFirstError: true,
                queue: queue,
                completion: { operationResult in
                    var finalResult: Result<[DateInterval], Swift.Error>!
                    switch operationResult {
                    case .success(let iterationsResults):
                        let finalElements = iterationsResults
                            .flatMap{ $0 }
                        finalResult = .success(finalElements)
                    case .failure(let error):
                        finalResult = .failure(error)
                    }
                    dispatchResultCompletion(result: finalResult, queue: queue, completion: completion)
            })
        }
    }
    
}

