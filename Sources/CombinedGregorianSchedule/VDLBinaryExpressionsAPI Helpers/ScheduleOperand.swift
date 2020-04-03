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




