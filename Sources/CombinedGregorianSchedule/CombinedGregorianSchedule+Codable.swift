//
//  CombinedGregorianSchedule
//  CombinedGregorianSchedule+Codable.swift
//
//  Created by Valeriano Della Longa on 03/04/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
import GregorianCommonTimetable
import VDLBinaryExpressionsAPI

extension CombinedGregorianSchedule: Codable {
    enum CodingKeys: String, CodingKey {
        case tokens
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tokens, forKey: .tokens)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tokens = try container.decode(Array<Token>.self, forKey: .tokens)
        self = try Self(tokens: tokens)
    }
    
}

