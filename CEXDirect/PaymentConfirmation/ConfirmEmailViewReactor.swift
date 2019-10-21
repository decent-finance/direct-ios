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

class ConfirmEmailViewReactor: Reactor {
    
    enum Action {
        case enterCode(String?)
        case submit
        case resendCode
    }
    
    enum Mutation {
        case setEmail(String?)
        case setCode(String?)
        case setCodeError(String?)
        case setAlert(String?)
        case setFinished
        case setLoading(Bool)
        case setCodeResend(Bool)
    }
    
    struct State {
        var email: String?
        var code: String?
        var codeError: String?
        var alert: String?
        var isFinished = false
        var isLoading = false
        var isCodeResend: Bool?
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .enterCode(let code):
            return .just(.setCode(code))
        case .submit:
            return mutateSubmit()
        case .resendCode:
            return .concat(.just(.setLoading(true)),
                orderService.rx.resendConfirmationCode(order: orderStore.order).map { _ in .setCodeResend(true) }
                    .catchErrorJustReturn(.setCodeResend(false)),
                .just(.setLoading(false)))
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return .merge(mutation, orderStore.rx_order.map { .setEmail($0.email) })
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        state.alert = nil
        state.isCodeResend = nil
        
        switch mutation {
        case .setEmail(let email):
            state.email = email
        case .setCode(let code):
            state.code = code
            state.codeError = nil
        case .setCodeError(let error):
            state.codeError = error
        case .setAlert(let alert):
            state.alert = alert
        case .setFinished:
            state.isFinished = true
        case let .setLoading(isLoading):
            state.isLoading = isLoading
        case let .setCodeResend(isCodeResend):
            state.isCodeResend = isCodeResend
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
        
        initialState = State(email: orderStore.order.email, code: nil, codeError: nil, alert: nil, isFinished: false, isLoading: false, isCodeResend: nil)
    }
    
    // MARK: - Implementation
    
    let orderService: OrderService
    let orderStore: OrderStore
    
    func mutateSubmit() -> Observable<Mutation> {
        if let code = currentState.code, code.count > 0 {
            return .concat(.just(.setLoading(true)),
                orderService.rx.checkConfirmationCode(code: code, order: orderStore.order).map { Mutation.setFinished }
                    .catchErrorJustReturn(.setAlert(NSLocalizedString("Failed to check email confirmation", comment: ""))),
                .just(.setLoading(false)))
        } else {
            return .just(.setCodeError(NSLocalizedString("Please enter a valid code", comment: "")))
        }
    }
}

