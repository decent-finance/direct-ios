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
//  Created by Ihor Vovk on 4/17/19.

import Foundation
import ReactorKit
import RxSwift

class ConfirmPaymentViewReactor: Reactor {
    
    enum Action {
    }
    
    enum Mutation {
        case setHTML(String)
    }
    
    struct State {
        var html: String?
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        return Observable.empty()
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let loadPaymentConfirmationHTMLObservable = orderService.rx.loadPaymentConfirmationHTML(order: orderStore.order).map { Mutation.setHTML($0) }
        return .merge(mutation, loadPaymentConfirmationHTMLObservable)
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .setHTML(let html):
            state.html = html
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        initialState = State()
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
    }
    
    // MARK: - Implementation
    
    private let orderService: OrderService
    private let orderStore: OrderStore
}
