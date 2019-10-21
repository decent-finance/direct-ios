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
//  Created by Ihor Vovk on 3/25/19.

import Foundation
import Alamofire
import CocoaLumberjack
import RxSwift

@objc public class PaymentService: BaseService {
    
    // MARK: - Private Data
    
    private let session: Session
    fileprivate let socketManager: SocketManager
    fileprivate let placementID: String
    private var baseURL: URL {
        return apiBaseURL.appendingPathComponent("payments")
    }
    
    init(session: Session, socketManager: SocketManager, placementID: String) {
        self.session = session
        self.socketManager = socketManager
        self.placementID = placementID
    }
    
    func loadCurrencies(success: @escaping ([CurrencyConversion]) -> Void, failure: @escaping (Error) -> Void) {
        session.cd_requestArray(baseURL.appendingPathComponent("currencies/\(placementID)"), keyPath: "data.currencies", success: success, failure: failure)
    }
    
    func loadCountries(success: @escaping ([Country]) -> Void, failure: @escaping (Error) -> Void) {
        session.cd_requestArray(baseURL.appendingPathComponent("countries"), keyPath: "data", success: success, failure: failure)
    }
    
    func verifyWallet(order: Order, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        success()
        
//        if let wallet = order.walletAddress, let currency = order.cryptoCurrency {
//            session.cd_request(baseURL.appendingPathComponent("wallet/\(wallet)/\(currency)/verify"), success: { _ in
//                success()
//            }, failure: failure)
//        } else {
//            failure(ServiceError.incorrectParameters)
//        }
    }
}

extension Reactive where Base : PaymentService {

    func loadCurrencies() -> Observable<[CurrencyConversion]> {
        return Observable.create { observable in
            self.base.loadCurrencies(success: { currenciesConversion in
                observable.onNext(currenciesConversion)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })

            return Disposables.create()
        }
    }
    
    func subscribeCurrencies() -> Observable<[CurrencyConversion]> {
        return base.socketManager.subscribe(event: "currencies") { [weak base] () -> SocketMessage in
            return SocketMessage(event: "currencies", messageData: base?.placementID)
        }.flatMap { message -> Observable<[CurrencyConversion]> in
            if let messageData = message.messageData as? [String: Any], let currencyConversionsJSON = messageData["currencies"] as? [[String: Any]] {
                let currencyConvertions = currencyConversionsJSON.compactMap { CurrencyConversion(JSON: $0) }
                return .just(currencyConvertions)
            } else {
                return .empty()
            }
        }
    }
    
    func loadCountries() -> Observable<[Country]> {
        return Observable.create { observable in
            self.base.loadCountries(success: { countries in
                observable.onNext(countries)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func verifyWallet(order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.verifyWallet(order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
}
