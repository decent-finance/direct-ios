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
//  Created by Ihor Vovk on 3/14/19.

import Foundation
import Alamofire
import CocoaLumberjack

class CDServerTrustPolicyManager: ServerTrustManager {
    
    override func serverTrustEvaluator(forHost host: String) -> ServerTrustEvaluating? {
        if let trustEvaluating = try? super.serverTrustEvaluator(forHost: host) {
            return trustEvaluating
        } else {
            return DisabledEvaluator()
        }
    }
}

@objc public class ServiceProvider: NSObject {
    
    let merchantService: MerchantService
    let paymentService: PaymentService
    let orderService: OrderService
    
    @objc public init(placementID: String, secret: String) {
        session = Session(configuration: URLSessionConfiguration.default, serverTrustManager: CDServerTrustPolicyManager(evaluators: ["cexd-service-dev.dev.kube": DisabledEvaluator()]))
        socketManager = SocketManager()
        
        merchantService = MerchantService(session: session, placementID: placementID)
        paymentService = PaymentService(session: session, socketManager: socketManager, placementID: placementID)
        orderService = OrderService(session: session, socketManager: socketManager, placementID: placementID, secret: secret)
        
        super.init()
        
//        sessionManager.delegate.sessionDidReceiveChallenge = { [weak self] session, challenge in
//            var disposition: URLSession.AuthChallengeDisposition = .useCredential
//            var credential: URLCredential? = nil
//            
//            if let serverTrust = challenge.protectionSpace.serverTrust, challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//                credential = URLCredential(trust: serverTrust)
//            } else if challenge.previousFailureCount > 0 {
//                disposition = .cancelAuthenticationChallenge
//            } else {
//                credential = self?.sessionManager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
//            }
//            
//            return (disposition, credential)
//        }
    }
    
    // MARK: - Private Data
    
    private let session: Session
    private let socketManager: SocketManager
}
