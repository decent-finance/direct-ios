//
//  Precisions.swift
//  CEXDirect
//
//  Created by Ihor Vovk on 4/10/19.
//  Copyright © 2019 Ihor Vovk. All rights reserved.
//

import Foundation
import ObjectMapper

class Precisions: Mappable {
    
    var type: String?
    var currency: String?
    var visiblePrecision: Int?
    var currencyPrecision: Int?
    var visibleRoundRule: String?
    
    required init?(map: Map){
    }
    
    func mapping(map: Map) {
        type <- map["type"]
        currency <- map["currency"]
        visiblePrecision <- map["visiblePrecision"]
        currencyPrecision <- map["currencyPrecision"]
        visibleRoundRule <- map["visibleRoundRule"]
    }
    
    func convertToCrypto(fiatAmount: String) -> String {
        return fiatAmount
    }
    
    func convertToFiat(cryptoAmount: String) -> String {
        return cryptoAmount
    }
}
