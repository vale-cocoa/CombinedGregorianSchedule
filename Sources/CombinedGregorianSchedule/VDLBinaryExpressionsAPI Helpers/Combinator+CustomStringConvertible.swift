//
//  CombinedSchedule
//  Combinator+CustomStringConvertible.swift
//  
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
extension Combinator: CustomStringConvertible {
    var description: String {
        switch self {
        case .refine:
            return ">>>"
        }
    }
}
