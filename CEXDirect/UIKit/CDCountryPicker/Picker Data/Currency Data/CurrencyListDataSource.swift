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
//  Created by Alex Kovalenko on 5/10/19.

import UIKit

class CurrencyListDataSource: NSObject {
    private var currencyArray = Dictionary<String, String>()
    
    override init() {
        super.init()
        parse()
    }
    
    private func parse() {
        if let url = Bundle(for: type(of: self)).url(forResource: "CurrencyNames", withExtension: "plist"), let currencyList = NSDictionary(contentsOf: url) as? Dictionary<String, String>  {
            self.currencyArray = currencyList
        }
    }
    
    private func fiatSymbolDict() -> Dictionary<String, String> {
        return ["USD" : "$", "EUR" : "€", "RUB" : "₽", "GBP" : "£"]
    }
    
    func currencyList() -> Dictionary<String, String> {
        return currencyArray
    }
    
    func currencyName(_ shortName: String) -> String {
        return currencyArray[shortName.lowercased()] ?? ""
    }
    
    func currencyArray(_ currencyArray: Array<String>) -> Array<Dictionary<String, String>> {
        
        var arr = Array<Dictionary<String, String>>()
        
        for currency in currencyArray {
            var dict = Dictionary<String, String>()
            
            dict[CDPickerEnum.code.rawValue] = currency
            dict[CDPickerEnum.name.rawValue] = currencyName(currency)
            
            arr.append(dict)
        }
        
        return arr
    }
    
    func isSymbolFiat(symbol: String?) -> Bool {
        return self.fiatSymbolDict().keys.contains(symbol ?? "")
    }
}
