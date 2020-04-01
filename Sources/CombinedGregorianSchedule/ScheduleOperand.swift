//
//  CombinedSchedule
//  ScheduleOperand.swift
//
//  Created by Valeriano Della Longa on 30/03/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
import Schedule
import GregorianCommonTimetable
import VDLBinaryExpressionsAPI

enum ScheduleOperand {
    case gregorianCommonTimetable(GregorianCommonTimetable)
    case evaluated(Schedule.Generator, Schedule.AsyncGenerator)
    
    var generators: (generator: Schedule.Generator, asyncGenerator: Schedule.AsyncGenerator) {
        switch self {
        case .gregorianCommonTimetable(let concrete):
            return (concrete.generator, concrete.asyncGenerator)
        case .evaluated(let generator, let asyncGenerator):
            return (generator, asyncGenerator)
        }
    }
    
}

extension ScheduleOperand: RepresentableAsEmptyProtocol {
    static func empty() -> ScheduleOperand {
        return .evaluated(emptyGenerator, emptyAsyncGenerator)
    }
    
    var isEmpty: Bool {
        return isEmptyGenerator(self.generators.generator)
    }
    
}

// MARK: - Codable conformance
extension ScheduleOperand: Codable {
    enum Error: Swift.Error {
        case notCodable
    }
    
    enum Base: String, Codable {
        case gregorianCommonTimetable
    }
    
    enum CodingKeys: String, CodingKey {
        case base
        case concrete
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .gregorianCommonTimetable(let concrete):
            try container.encode(Base.gregorianCommonTimetable, forKey: .base)
            try container.encode(concrete, forKey: .concrete)
        case .evaluated(_, _):
            throw Error.notCodable
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)
        switch base {
        case .gregorianCommonTimetable:
            let concrete = try container.decode(GregorianCommonTimetable.self, forKey: .concrete)
            self = .gregorianCommonTimetable(concrete)
        }
    }
    
}


