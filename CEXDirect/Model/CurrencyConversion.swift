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
    var a: Decimal?
    var b: Decimal?
    var c: Decimal?
    var fiatPopularValues: [String]?
    var cryptoPopularValues: [String]?
    
    init() {
    }
    
    public init?(map: Map){
        if let mapA = map["a"].currentValue as? NSNumber {
            a = mapA.decimalValue
        }
        
        if let mapB = map["b"].currentValue as? NSNumber {
            b = mapB.decimalValue
        }
        
        if let mapC = map["c"].currentValue as? NSNumber {
            c = mapC.decimalValue
        }
    }
    
    mutating public func mapping(map: Map) {
        fiat <- map["fiat"]
        crypto <- map["crypto"]
        fiatPopularValues <- map["fiatPopularValues"]
        cryptoPopularValues <- map["cryptoPopularValues"]
    }
    
    func convertToCrypto(fiatAmount: String, precision: Int, roundRule: String?) -> String {
        guard let a = a, let b = b, let c = c, c != Decimal(0), let decimalFiatAmount = Decimal(string: fiatAmount, locale: Locale.current) else { return "" }

        let result = (a * decimalFiatAmount - b) / c

        let formatter = NumberFormatter()
        formatter.roundingMode = roundRule == "trunk" ? .down : .halfUp
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = precision
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false

        return formatter.string(from: NSDecimalNumber(decimal: result)) ?? ""
    }
    
    func convertToFiat(cryptoAmount: String, precision: Int, roundRule: String?) -> String {
        guard let a = a, let b = b, let c = c, a != Decimal(0), let decimalCryptoAmount = Decimal(string: cryptoAmount, locale: Locale.current) else { return "" }
         
        let result = (c * decimalCryptoAmount + b) / a

        let formatter = NumberFormatter()
        formatter.roundingMode = roundRule == "trunk" ? .down : .halfUp
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = precision
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false

        return formatter.string(from: NSDecimalNumber(decimal: result)) ?? ""
    }
}
