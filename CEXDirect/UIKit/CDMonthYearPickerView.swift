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
//  Created by Alexandr Kovalenko on 10/28/19.

import UIKit

class CDMonthYearPickerView: UIPickerView {
    
    private var months: [String] = []
    private var years: [Int] = []
    
    var month = Calendar.current.component(.month, from: Date()) {
        didSet {
            selectRow(month - 1, inComponent: 0, animated: false)
        }
    }
    
    var year = Calendar.current.component(.year, from: Date()) {
        didSet {
            selectRow(years.firstIndex(of: year)!, inComponent: 1, animated: true)
        }
    }
    
    var onSelect: ((_ selectedDate: Date) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonSetup()
    }
    
    private func commonSetup() {
        var years: [Int] = []
        if years.count == 0 {
            let currentYear = NSCalendar.current.component(.year, from: Date())
            for year in currentYear...currentYear + 15 {
                years.append(year)
            }
        }
        self.years = years
        
        var months: [String] = []
        for month in DateFormatter().monthSymbols {
            months.append(month.capitalized)
        }
        self.months = months
        
        self.delegate = self
        self.dataSource = self
        
        let currentMonth = NSCalendar.current.component(.month, from: Date())
        self.selectRow(currentMonth - 1, inComponent: 0, animated: false)
    }
    
    private var dateFormatter: DateFormatter {
        let result = DateFormatter()
        result.dateFormat = "MM/yyyy"
        return result
    }
}

extension CDMonthYearPickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return months[row]
        case 1:
            return "\(years[row])"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let month = self.selectedRow(inComponent: 0) + 1
        let year = years[self.selectedRow(inComponent: 1)]
        let selectedDateString = "\(month)/\(year)"
        
        if let date = self.dateFormatter.date(from: selectedDateString), let closure = onSelect {
            closure(date)
        }
        
        self.month = month
        self.year = year
    }
}

extension CDMonthYearPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return months.count
        case 1:
            return years.count
        default:
            return 0
        }
    }
}
