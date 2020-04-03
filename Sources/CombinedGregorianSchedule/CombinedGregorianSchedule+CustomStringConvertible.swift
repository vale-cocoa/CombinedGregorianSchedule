//
//  CombinedGregorianSchedule
//  CombinedGregorianSchedule+CustomStringConvertible.swift
//  
//  Created by Valeriano Della Longa on 03/04/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
import VDLBinaryExpressionsAPI

extension CombinedGregorianSchedule: CustomStringConvertible {
    public var description: String {
        
        return tokens.validInfix()!.description
    }
    
}
