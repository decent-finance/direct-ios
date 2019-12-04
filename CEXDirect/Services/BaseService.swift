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
//  Created by Ihor Vovk on 4/15/19.

import Foundation
import CocoaLumberjack

enum ServiceError: Error {
    
    case incorrectParameters
    case incorrectResponseData
    case locationNotSupported
}

public class BaseService: NSObject {
    
    let serviceDataKey = "serviceData"
    let dataKey = "data"
    
    var nonce: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    var sourceURI: String? {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            return "ios://" + bundleIdentifier
        } else {
            return nil
        }
    }
    
    let apiBaseURL: URL
    
    init(configuration: Configuration) {
        apiBaseURL = configuration.apiBaseURL
    }
}
