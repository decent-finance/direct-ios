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
//  Created by Ihor Vovk on 11/22/19.

import Foundation
import ReactorKit
import RxSwift

class PaymentRefundedViewReactor: Reactor {
    
    enum Action {
    }
    
    enum Mutation {
    }
    
    struct State {
        var currencyImageName: String?
        var returnedAmount: String?
        var card: String?
    }
    
    let initialState: State
    
    init(orderStore: OrderStore) {
        var state = State()
        if let amount = orderStore.order.fiatAmount, let currency = orderStore.order.fiatCurrency {
            state.currencyImageName = "refund_\(currency.lowercased())"
            state.returnedAmount = "\(amount) \(currency)"
        }
        
        state.card = "**** **** **** \(orderStore.order.cardBin ?? "****")"
        
        initialState = state
    }
}
