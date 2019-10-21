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

@objc public class MerchantService: BaseService {
    
    // MARK: - Private Data
    
    private let session: Session
    private let placementID: String
    private var baseURL: URL {
        return apiBaseURL.appendingPathComponent("merchant")
    }
    
    init(session: Session, placementID: String) {
        self.session = session
        self.placementID = placementID
    }
    
    func loadPlacementInfo(success: @escaping (Placement) -> Void, failure: @escaping (Error) -> Void) {
        session.cd_requestObject(baseURL.appendingPathComponent("placement/check/\(placementID)"), keyPath: "data", success: success, failure: failure)
    }
    
    func loadRule(id: String, success: @escaping (Rule) -> Void, failure: @escaping (Error) -> Void) {
        session.cd_requestObject(baseURL.appendingPathComponent("rules/\(id)"), keyPath: "data", success: success, failure: failure)
    }
    
    func loadCurrencyPrecisions(success: @escaping ([CurrencyPrecision]) -> Void, failure: @escaping (Error) -> Void) {
        session.cd_requestArray(baseURL.appendingPathComponent("precisions/\(placementID)"), keyPath: "data.precisions", success: success, failure: failure)
    }
    
//    func checkURL(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
//        sessionManager.request(baseURL.appendingPathComponent("merchants/source/check"), method: .get).validate().responseJSON { response in
//            switch response.result {
//            case .success(let result):
//                DDLogInfo("Successfully checked URL")
//                success()
//            case .failure(let error):
//                DDLogError("Failed to check URL - \(error)")
//                failure(error)
//            }
//        }
//    }
}

extension Reactive where Base : MerchantService {
    
    func loadPlacementInfo() -> Observable<Placement> {
        return Observable.create { observable in
            self.base.loadPlacementInfo(success: { placement in
                observable.onNext(placement)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func loadRule(id: String) -> Observable<Rule> {
        return Observable.create { observable in
            self.base.loadRule(id: id, success: { rule in
                observable.onNext(rule)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func loadCurrencyPrecisions() -> Observable<[CurrencyPrecision]> {
        return Observable.create { observable in
            self.base.loadCurrencyPrecisions(success: { currencyPrecisions in
                observable.onNext(currencyPrecisions)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
}
