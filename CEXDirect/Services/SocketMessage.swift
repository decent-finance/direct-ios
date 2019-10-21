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
//  Created by Ihor Vovk on 5/20/19.

import Foundation

struct SocketMessage {
    
    let event: String
    let messageData: Any?
    
    var dataRepresentation: Data? {
        var json: [String: Any] = ["event": event]
        if let messageData = messageData {
            json["data"] = messageData
        }
        
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    init?(data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let event = json["event"] as? String {
            self.event = event
            self.messageData = (json["data"] as? [String: Any])?["data"]
        } else {
            return nil
        }
    }
    
    init?(text: String) {
        if let data = text.data(using: .utf8) {
            self.init(data: data)
        } else {
            return nil
        }
    }
    
    init(event: String, messageData: Any?) {
        self.event = event
        self.messageData = messageData
    }
}
