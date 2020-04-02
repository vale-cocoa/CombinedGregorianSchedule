//
//  CombinedSchedule
//  Combinator+WebAPICodingOptions.swift
//  
//  Created by Valeriano Della Longa on 02/04/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//

import Foundation
import Schedule
import GregorianCommonTimetable
import VDLBinaryExpressionsAPI
import VDLGCDHelpers
import VDLCalendarUtilities
import WebAPICodingOptions

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
        if
            let codingOptions = encoder.userInfo[WebAPICodingOptions.key] as? WebAPICodingOptions
        {
            switch codingOptions.version {
            case .v1:
                let webInstance = _WebApiCombinator(self)
                try webInstance.encode(to: encoder)
            }
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(Base(self), forKey: .base)
        }
        
    }
    
    public init(from decoder: Decoder) throws {
        if
            let codingOptions = decoder.userInfo[WebAPICodingOptions.key] as? WebAPICodingOptions
        {
            switch codingOptions.version {
            case .v1:
                let webInstance = try _WebApiCombinator(from: decoder)
                guard
                    let combinator = webInstance.concrete
                    else {
                    throw WebAPICodingOptions.Error.invalidDecodedValues(webInstance.combinator)
                }
                
                self = combinator
            }
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let base = try container.decode(Base.self, forKey: .base)
            self = base.combinator
        }
    }
}

fileprivate class _WebApiCombinator: Codable {
    let combinator: String
    
    init(_ combinator: Combinator) {
        switch combinator {
        case .refine:
            self.combinator = ">>>"
        }
    }
    
    var concrete: Combinator? {
        return combinator == ">>>" ? .refine : nil
    }
    
}
