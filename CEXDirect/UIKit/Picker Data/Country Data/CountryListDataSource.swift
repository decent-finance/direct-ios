//
//  CountryListDataSource.swift
//  SuperScheet
//
//  Created by Alex Kovalenko on 4/18/19.
//  Copyright © 2019 Alex Kovalenko. All rights reserved.
//

import UIKit

class CountryListDataSource: NSObject {
    
    static let shared = CountryListDataSource()
    
    var countriesList = [Dictionary<String, String>]()
    
    private override init() {
        super.init()
        parseJSON()
    }
    
    private func parseJSON() {
        
        if let url = Bundle(for: type(of: self)).url(forResource: "countries", withExtension: "json"), let data = try? Data(contentsOf: url) {
            
            if let countries = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Dictionary<String, String>] {
                countriesList = countries
            }
        }
    }
    
    func countries() -> Array<Dictionary<String, String>> {
        return countriesList
    }
    
    func countryName(code : String?) -> String {
        for countryDict in countriesList {
            if let countryCode = countryDict["code"] {
                if countryCode == code {
                    return countryDict["name"] ?? ""
                }
            }
        }
        
        return ""
    }
}
