// Copyright 2019 CEX.​IO Ltd (UK)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Ihor Vovk on 4/10/19.

import Foundation
import ObjectMapper

struct CurrencyConversion: Mappable {
    
    var fiat: String?
    var crypto: String?
    var a: Double?
    var b: Double?
    var c: Double?
    var fiatPopularValues: [String]?
    var cryptoPopularValues: [String]?
    
    init() {
    }
    
    public init?(map: Map){
    }
    
    mutating public func mapping(map: Map) {
        fiat <- map["fiat"]
        crypto <- map["crypto"]
        a <- map["a"]
        b <- map["b"]
        c <- map["c"]
        fiatPopularValues <- map["fiatPopularValues"]
        cryptoPopularValues <- map["cryptoPopularValues"]
    }
    
    func convertToCrypto(fiatAmount: String, precision: Int, roundRule: String?) -> String {
        guard let a = a, let b = b, let c = c, c != 0, let doubleFiatAmount = Double(fiatAmount) else { return "" }
        
        let result = (a * doubleFiatAmount - b) / c
        
        let formatter = NumberFormatter()
        formatter.roundingMode = roundRule == "trunk" ? .down : .halfUp
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = precision
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        
        return formatter.string(from: NSNumber(floatLiteral: result)) ?? ""
    }
    
    func convertToFiat(cryptoAmount: String, precision: Int, roundRule: String?) -> String {
        guard let a = a, let b = b, let c = c, a != 0, let doubleCryptoAmount = Double(cryptoAmount) else { return "" }
        
        let result = (c * doubleCryptoAmount + b) / a
        
        let formatter = NumberFormatter()
        formatter.roundingMode = roundRule == "trunk" ? .down : .halfUp
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = precision
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        
        return formatter.string(from: NSNumber(floatLiteral: result)) ?? ""
    }
}
