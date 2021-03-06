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
    
    let durationOfRhsElement = rhs(.distantPast, .firstAfter)?.duration ?? rhs(.distantFuture, .firstBefore)!.duration
    let maxRhsIterations: Int!
    if durationOfRhsElement <= 3600 {
        maxRhsIterations = 24
    } else if durationOfRhsElement <= (3600*24) {
        maxRhsIterations = 31
    } else {
        maxRhsIterations = 12
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
        var rhsIterations = 0
        while
            rhsIterations <= maxRhsIterations,
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
            rhsIterations += 1
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
            var lhsCandidate: DateInterval? = lhs(date, .on) ?? lhsDateInterval
            var rhsCandidate: DateInterval? =  rhs(date, .firstAfter)
            var lhsIterations = 0
            while
                lhsIterations <= maxLhsIterations,
                let lhsResult = lhsCandidate
            {
                var rhsIterations = 0
                while
                    rhsIterations <= maxRhsIterations,
                    let rhsResult = rhsCandidate,
                    rhsResult.start <= lhsResult.end
                {
                    if
                        let intersection = lhsResult.intersection(with: rhsResult),
                        intersection.duration == rhsResult.duration
                    {
                        return rhsResult
                    }
                    rhsCandidate = rhs(rhsResult.start, .firstAfter)
                    rhsIterations += 1
                }
                lhsCandidate = lhs(lhsResult.start, .firstAfter)
                lhsIterations += 1
                if lhsCandidate != nil {
                    rhsCandidate = rhs(lhsCandidate!.start, .on) ?? rhs(lhsCandidate!.start, .firstAfter)
                }
            }
            
            return nil
        
        case .firstBefore:
            var lhsCandidate: DateInterval? = lhs(date, .on) ?? lhsDateInterval
            var rhsCandidate: DateInterval? = rhs(date, .firstBefore)
            var lhsIterations = 0
            while
                lhsIterations <= maxLhsIterations,
                let lhsResult = lhsCandidate
            {
                var rhsIterations = 0
                while
                    rhsIterations <= maxRhsIterations,
                    let rhsResult = rhsCandidate,
                    rhsResult.start >= lhsResult.start
                {
                    if
                        let intersection = lhsResult.intersection(with: rhsResult),
                        intersection.duration == rhsResult.duration
                    {
                        
                        return rhsResult
                    }
                    rhsCandidate = rhs(rhsResult.start, .firstBefore)
                    rhsIterations += 1
                }
                lhsCandidate = lhs(lhsResult.start, .firstBefore)
                lhsIterations += 1
                if lhsCandidate != nil {
                    rhsCandidate = rhs(lhsCandidate!.end, .on) ?? rhs(lhsCandidate!.end, .firstBefore)
                }
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

