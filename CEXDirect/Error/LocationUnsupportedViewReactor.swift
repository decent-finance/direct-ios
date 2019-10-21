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
//  Created by Ihor Vovk on 7/16/19.

import Foundation
import ReactorKit
import RxSwift

class LocationUnsupportedViewReactor: Reactor {
    
    enum Action {
        case editEmail(String?)
        case agreeToReceiveNotification(Bool)
        case informMe
    }
    
    enum Mutation {
        case setEmail(String?)
        case setEmailError(String?)
        case setAgreedToReceiveNotification(Bool)
        case setAgreeToReceiveNotificationError(Bool)
    }
    
    struct State {
        var email: String?
        var emailError: String?
        var isAgreedToReceiveNotification = false
        var agreeToReceiveNotificationError = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .editEmail(let email):
            return .just(.setEmail(email))
        case .agreeToReceiveNotification(let isAgreed):
            return .just(.setAgreedToReceiveNotification(isAgreed))
        case .informMe:
            return mutateInformMe()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .setEmail(let email):
            state.email = email
            state.emailError = nil
        case .setEmailError(let error):
            state.emailError = error
        case .setAgreedToReceiveNotification(let isAgreed):
            state.isAgreedToReceiveNotification = isAgreed
            state.agreeToReceiveNotificationError = false
        case .setAgreeToReceiveNotificationError(let error):
            state.agreeToReceiveNotificationError = error
        }
        
        return state
    }
    
    init(orderStore: OrderStore) {
        initialState = State(email: orderStore.order.email, emailError: nil, isAgreedToReceiveNotification: false, agreeToReceiveNotificationError: false)
    }
    
    // MARK: - Implementation
    
    func mutateInformMe() -> Observable<Mutation> {
        guard let email = currentState.email, email.count > 0 else {
            return .just(.setEmailError(NSLocalizedString("Please enter a valid email", comment: "")))
        }
        
        guard currentState.isAgreedToReceiveNotification else {
            return .just(.setAgreeToReceiveNotificationError(true))
        }
        
        return .empty()
    }
}

