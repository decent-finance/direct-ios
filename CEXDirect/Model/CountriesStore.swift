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
//  Created by Ihor Vovk on 9/2/19.

import Foundation

public class CountriesStore {
    
    var countries: [Country] {
        get {
            return queue.sync { countriesStorage }
        }
        
        set(newCountries) {
            queue.sync {
                countriesStorage = newCountries
            }
        }
    }
    
    // MARK: - Implementation
    
    private let queue = DispatchQueue(label: "com.cexdirect.CountriesStoreQueue")
    private var countriesStorage: [Country] = []
}
