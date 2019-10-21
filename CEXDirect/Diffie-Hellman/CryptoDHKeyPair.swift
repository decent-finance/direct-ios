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
//  Created by Viktor Gubriienko on 3/4/19.

import Foundation
import BigInt


class CryptoDHKeyPair: CryptoKeyPair {
    
    enum Error: Swift.Error {
        case badPublicKey
    }
    
    let publicKey: String
    
    private let group: CryptoDHGroup
    
    private let xValue: BigUInt
    private let yValue: BigUInt
    
    init(group: CryptoDHGroup) {
        self.group = group
        
        xValue = BigUInt.randomInteger(lessThan: group.prime)
        yValue = group.generator.power(xValue, modulus: group.prime)
        publicKey = yValue.serialize().base64EncodedString()
    }
    
    func createSharedSecret(publicKey: String) throws -> String {
        guard let publicKeyData = Data(base64Encoded: publicKey) else {
            throw Error.badPublicKey
        }
        
        let serverPublicKey = BigUInt(publicKeyData)
        
        let sharedSecret = serverPublicKey.power(xValue, modulus: group.prime)
        return sharedSecret.serialize().base64EncodedString()
    }
    
}
