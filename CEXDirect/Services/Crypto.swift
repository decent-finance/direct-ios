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
//  Created by Viktor Gubriienko on 3/1/19.

import Foundation
import CryptoSwift


class Crypto {

    private struct Constants {
        static let fillerPartKey = "randomFillerPart"
        static let randomRangeString = "0123456789"
        static let fillerRandomLength = 16
        static let jsonRandomLength = 5
        static let vectorRandomLength = 3
    }
    
    struct Encrypted: Codable {
        let initialVector: String   // Base64 encoded initial vector string
        let encryptedValue: String  // Base64 encoded ciphered string
        let secretId: String        // Server secret ID used for device session linking
    }
    
    class func encrypt(_ dict: [String: Any], sharedSecretKey: String, secretId: String) throws -> Encrypted {
        let timestamp = String(format: "%.f", Date().timeIntervalSince1970 * 1000)
        
        var encodingDict = dict
        encodingDict[Constants.fillerPartKey] = createRandomString(length: Constants.fillerRandomLength) + timestamp

        let encodingData = try JSONSerialization.data(withJSONObject: encodingDict, options: [])
        let encodingString = createRandomString(length: Constants.jsonRandomLength) + String(data: encodingData, encoding: .utf8)!

        let hashedSharedSecret = sharedSecretKey.bytes.sha256()
        
        let initialVectorString = createRandomString(length: Constants.vectorRandomLength) + timestamp
        let initialVectorBase64Data = initialVectorString.data(using: .utf8)!
        let initialVectorBase64String = initialVectorBase64Data.base64EncodedString()
        
        let encrypted = try encryptWithAES256CBC(input: encodingString.bytes,
                                                 secterKey: hashedSharedSecret,
                                                 initialVector: initialVectorBase64Data.bytes)

        return Encrypted(initialVector: initialVectorBase64String,
                         encryptedValue: Data(encrypted).base64EncodedString(),
                         secretId: secretId)
    }
    
    class private func createRandomString(length: Int) -> String {
        return String((0..<length).map {_ in Constants.randomRangeString.randomElement()!})
    }
    
    class private func encryptWithAES256CBC(input: [UInt8], secterKey: [UInt8], initialVector: [UInt8]) throws -> [UInt8] {
        let aes = try AES(key: secterKey, blockMode: CBC(iv: initialVector))
        let encrypted = try aes.encrypt(input)
        return encrypted
    }
    
    class private func decryptWithAES256CBC(input: [UInt8], secretKey: [UInt8], initialVector: [UInt8]) throws -> [UInt8] {
        let aes = try AES(key: secretKey, blockMode: CBC(iv: initialVector))
        let decrypted = try aes.decrypt(input)
        return decrypted
    }
    
}
