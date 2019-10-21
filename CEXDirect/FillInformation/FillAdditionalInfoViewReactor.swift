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
//  Created by Ihor Vovk on 5/10/19.

import Foundation
import ReactorKit
import RxSwift

class FillAdditionalInfoViewReactor: Reactor {
    
    enum Action {
        case edit(property: Order.AdditionalInfoKey, value: String?)
        case verify
    }
    
    enum Mutation {
        case set(property: Order.AdditionalInfoKey, value: String?)
        case setValidationErrors([String: String])
        case setAlert(String?)
        case update(Order)
        case setFinished
        case setLoading(Bool)
    }
    
    struct State {
        var additionalInfo: [String: Order.AdditionalInfo]
        var validationErrors: [String: String]
        var alert: String?
        var isFinished = false
        var isLoading = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .edit(let property, let value):
            return Observable.just(Mutation.set(property: property, value: value))
        case .verify:
            return mutateVerify()
        }
    }
    
//    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
//        let updateMutation = orderService.rx.subscribeOrderUpdates(order: orderStore.order).map { Mutation.update($0) }
//        return .merge(mutation, updateMutation)
//    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        state.alert = nil
        
        switch mutation {
        case .set(let property, let value):
            state.additionalInfo[property.rawValue]?.value = value
            state.validationErrors.removeValue(forKey: property.rawValue)
        case .setValidationErrors(let errors):
            state.validationErrors = errors
        case .setAlert(let alert):
            state.alert = alert
        case .update(let order):
            state = reduceUpdate(state: state, order: order)
        case .setFinished:
            state.isFinished = true
        case let .setLoading(isLoading):
            state.isLoading = isLoading
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
        
        var additionalInfo = orderStore.order.additionalInfo?.filter { (pair: (key: String, value: Order.AdditionalInfo)) -> Bool in
            return pair.value.isRequired
        }
        
        // Workaround for backend issues
        additionalInfo?[Order.AdditionalInfoKey.userResidentialCountry.rawValue]?.value = orderStore.order.country
        additionalInfo?[Order.AdditionalInfoKey.userResidentialCountry.rawValue]?.isEditable = false
        additionalInfo?[Order.AdditionalInfoKey.billingCounty.rawValue]?.value = orderStore.order.country
        additionalInfo?[Order.AdditionalInfoKey.billingCounty.rawValue]?.isEditable = false
        additionalInfo?[Order.AdditionalInfoKey.billingState.rawValue]?.value = orderStore.order.state
        additionalInfo?[Order.AdditionalInfoKey.billingState.rawValue]?.isEditable = false
        
        initialState = State(additionalInfo: additionalInfo ?? [:], validationErrors: [:], alert: nil, isFinished: false, isLoading: false)
    }
    
    // MARK: - Implementation
    
    private let orderService: OrderService
    private var orderStore: OrderStore
    
    func mutateVerify() -> Observable<Mutation> {
        var order = orderStore.order
        order.additionalInfo = currentState.additionalInfo.filter { (key: String, value: Order.AdditionalInfo) -> Bool in
            // Workaround for backend issues
            return ![Order.AdditionalInfoKey.userResidentialCountry.rawValue, Order.AdditionalInfoKey.billingCounty.rawValue, Order.AdditionalInfoKey.billingState.rawValue].contains(key)
        }
        
        orderStore.update(order: order)
        
        let errors = order.additionalInfo?.filter { (pair: (key: String, value: Order.AdditionalInfo)) -> Bool in
            return pair.value.isRequired && (pair.value.value == nil || pair.value.value?.isEmpty == true)
        }.reduce(into: [:]) { (result: inout [String: String], pair) in
            let additionalInfoKey = Order.AdditionalInfoKey(rawValue: pair.key)
            result[pair.key] = additionalInfoKey?.errorMessage
        }
        
        if let errors = errors, errors.count > 0 {
            return Observable.just(.setValidationErrors(errors))
        } else {
            return .concat(.just(.setLoading(true)),
                orderService.rx.updatePaymentData(order: order).do(onNext: { [weak self] order in
                    self?.orderStore.update(order: order)
                }).map { _ in .setFinished }.catchErrorJustReturn(.setAlert(NSLocalizedString("Failed to send data", comment: ""))),
                .just(.setLoading(false)))
        }
    }
    
    private func reduceUpdate(state: State, order: Order) -> State {
        var result = state
        if state.additionalInfo.count == 0 {
            result.additionalInfo = order.additionalInfo ?? [:]
        }
        
        return result
    }
}
