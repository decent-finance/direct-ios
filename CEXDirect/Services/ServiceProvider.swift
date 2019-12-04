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

@objc public class ServiceProvider: NSObject {
    
    let merchantService: MerchantService
    let paymentService: PaymentService
    let orderService: OrderService
    
    @objc public init(placementID: String, secret: String) {
        let configuration = Configuration()
        
        var hostEvaluators: [String: ServerTrustEvaluating] = [:]
        if let apiBaseURLHost = configuration.apiBaseURL.host {
            hostEvaluators[apiBaseURLHost] = configuration.disableCertificateEvaluation ? DisabledEvaluator() : DefaultTrustEvaluator()
        }
        
        session = Session(configuration: URLSessionConfiguration.default, serverTrustManager: ServerTrustManager(evaluators: hostEvaluators))
        socketManager = SocketManager(configuration: configuration)
        
        merchantService = MerchantService(session: session, placementID: placementID, configuration: configuration)
        paymentService = PaymentService(session: session, socketManager: socketManager, placementID: placementID, configuration: configuration)
        orderService = OrderService(session: session, socketManager: socketManager, placementID: placementID, secret: secret, configuration: configuration)
        
        super.init()
    }
    
    // MARK: - Private Data
    
    private let session: Session
    private let socketManager: SocketManager
}
