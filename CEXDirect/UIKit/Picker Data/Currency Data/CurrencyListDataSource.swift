//
//  CurrencyListDataSource.swift
//  CEXDirect
//
//  Created by Alex Kovalenko on 5/10/19.
//  Copyright © 2019 Ihor Vovk. All rights reserved.
//

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
}
