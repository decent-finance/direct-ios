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
//  Created by Ihor Vovk on 5/16/19.

import Foundation
import ReactorKit
import RxSwift

class EditEmailViewReactor: Reactor {
    
    enum Action {
        case editEmail(String?)
        case save
    }
    
    enum Mutation {
        case setEmail(String?)
        case setEmailError(String?)
        case setAlert(String?)
        case setFinished
        case setLoading(Bool)
    }
    
    struct State {
        var email: String?
        var emailError: String?
        var alert: String?
        var isFinished = false
        var isLoading = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .editEmail(let email):
            return .just(.setEmail(email))
        case .save:
            if let newEmail = currentState.email, DataValidator.isValid(email: newEmail) {
                return .concat(.just(.setLoading(true)),
                    orderService.rx.updateEmail(newEmail: newEmail, order: orderStore.order).do(onNext: { order in
                        self.orderStore.update(order: order)
                    }).map { _ in .setFinished }.catchErrorJustReturn(.setAlert(NSLocalizedString("Failed to save email", comment: ""))),
                    .just(.setLoading(false)))
            } else {
                return .just(.setEmailError(NSLocalizedString("Please enter a valid email", comment: "")))
            }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        state.alert = nil
        
        switch mutation {
        case .setEmail(let email):
            state.email = email
        case .setEmailError(let error):
            state.emailError = error
        case .setAlert(let alert):
            state.alert = alert
        case .setFinished:
            state.isFinished = true
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
        
        initialState = State(email: orderStore.order.email, emailError: nil, alert: nil, isFinished: false, isLoading: false)
    }
    
    // MARK: - Implementation
    
    let orderService: OrderService
    let orderStore: OrderStore
}
