//
//  CombinedSchedule
//  ScheduleOperand+CustomStringConvertible.swift
//
//  Created by Valeriano Della Longa on 03/04/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation

extension ScheduleOperand: CustomStringConvertible {
    var description: String {
        switch self {
        case .evaluated(_, _):
            return "ScheduleOperand.evaluated(_, _)"
        case .gregorianCommonTimetable(let concrete):
            return concrete.description
        }
    }
}
