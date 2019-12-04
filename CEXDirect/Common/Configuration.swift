// Copyright 2019 CEX.​IO Ltd (UK)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may  not use this file except in compliance with the License.
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
//  Created by Ihor Vovk on 12/2/19.

import Foundation
import CocoaLumberjack

struct Configuration {
    
    var apiBaseURL: URL {
        if let apiBaseURLString = configuration?["APIBaseURL"] as? String, let apiBaseURL = URL(string: apiBaseURLString) {
            return apiBaseURL
        } else {
            DDLogError("Failed to find API base URL")
            return URL(string: "https://apple.com")!
        }
    }
    
    var webSocketURL: URL {
        if let webSocketURLString = configuration?["WebSocketURL"] as? String, let webSocketURL = URL(string: webSocketURLString) {
            return webSocketURL
        } else {
            DDLogError("Failed to find web socket URL")
            return URL(string: "https://apple.com")!
        }
    }
    
    var disableCertificateEvaluation: Bool {
        configuration?["DisableCertificateEvaluation"] as? Bool ?? false
    }
    
    subscript(key: String) -> Any? {
        return configuration?[key]
    }
    
    // MARK: - Implementation
    
    private let configuration: NSDictionary? = {
        if let configurationPath = Bundle(for: SocketManager.self).path(forResource: "Configuration", ofType: "plist") {
            return NSDictionary(contentsOfFile: configurationPath)
        } else {
            return nil
        }
    }()
}
