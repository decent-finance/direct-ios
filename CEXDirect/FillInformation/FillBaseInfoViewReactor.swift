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
//  Created by Ihor Vovk on 3/28/19.

import Foundation
import ReactorKit
import RxSwift

class FillBaseInfoViewReactor: Reactor {
    
    enum BaseInfoKey {
        case email
        case country
        case state
    }
    
    enum Action {
        case enterEmail(String?)
        case selectCountry(String)
        case selectCountryName(String)
        case selectState(String?)
        case selectStateCode(String?)
        case submit
    }
    
    enum Mutation {
        case setEmail(String?)
        case setCountry(String)
        case setCountryName(String)
        case setState(String?)
        case setStateCode(String?)
        case setError(Bool)
        case setFinished
        case setLocationNotSupported(Bool)
        case setLoading(Bool)
        case setValidationErrors([BaseInfoKey: String])
    }
    
    struct State {
        var email: String?
        var countries: [Country]
        var countryStates: [CountryState]?
        var country: String?
        var countryName: String?
        var stateName: String?
        var stateCode: String?
        var isStateAvailable = false
        var submitTitle: String
        var isEditable = true
        var error = false
        var isFinished = false
        var locationNotSupported = false
        var isLoading = false
        var validationErrors: [BaseInfoKey: String]
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .submit:
            return mutateSubmit()
        case let .enterEmail(email):
            return Observable.just(Mutation.setEmail(email))
        case let .selectCountry(country):
            return Observable.just(Mutation.setCountry(country))
        case let .selectCountryName(countryName):
            return Observable.just(Mutation.setCountryName(countryName))
        case let .selectState(state):
            return Observable.just(Mutation.setState(state))
        case let .selectStateCode(stateCode):
            return Observable.just(Mutation.setStateCode(stateCode))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case let .setEmail(email):
            state = reduceEmail(state: state, email: email)
        case let .setCountry(country):
            state = reduceSetCountry(state: state, country: country)
        case let .setCountryName(countryName):
            state.countryName = countryName
        case let .setState(countryState):
            state = reduceCountryState(state: state, countryState: countryState)
        case let .setError(error):
            state.error = error
        case .setFinished:
            state.isFinished = true
        case .setLocationNotSupported(let isSupported):
            state.locationNotSupported = isSupported
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        case .setValidationErrors(let errors):
            state.validationErrors = errors
        case .setStateCode(let stateCode):
            state.stateCode = stateCode
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore, countriesStore: CountriesStore, isEditing: Bool = false) {
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
        
        let order = orderStore.order
        let country = countriesStore.countries.filter { (country) -> Bool in
            country.code == order.country
        }
        let state = country.first?.states?.filter({ (countryState) -> Bool in
            countryState.code == order.state
        })
        let submitTitle = NSLocalizedString(isEditing ? "SAVE" : "NEXT", comment: "")
        initialState = State(email: order.email, countries: countriesStore.countries, countryStates: country.first?.states, country: order.country, countryName: country.first?.name, stateName: state?.first?.name, stateCode: order.state, isStateAvailable: order.country == "US" , submitTitle: submitTitle, isEditable: !isEditing, error: false, isFinished: false, locationNotSupported: false, isLoading: false, validationErrors: [:])
    }
    
    // MARK: - Implementation
    
    private let orderService: OrderService
    private var orderStore: OrderStore
    
    func mutateSubmit() -> Observable<Mutation> {
        var order = orderStore.order
        order.email = currentState.email
        order.country = currentState.country
        order.state = currentState.stateCode
        
        orderStore.order = order
        
        if errorDict().count > 0 {
            return .just(.setValidationErrors(errorDict()))
        }
        
        return .concat(.of(.setLoading(true), .setLocationNotSupported(false)),
            orderService.rx.createOrder(order: order).do(onNext: { [weak self] order in
                self?.orderStore.order = order
            }).map { order in Mutation.setFinished }.catchError({ error -> Observable<Mutation> in
                if case ServiceError.locationNotSupported = error {
                    return .just(.setLocationNotSupported(true))
                } else {
                    return .just(.setError(true))
                }
            }),
            .just(.setLoading(false)))
    }
    
    private func errorDict() -> [BaseInfoKey: String] {
        var errorDict = [BaseInfoKey: String]()
        
        let email = currentState.email ?? ""
        if email.count == 0 || !DataValidator.isValid(email: email) {
            errorDict[.email] = NSLocalizedString("Please enter a valid email", comment: "")
        }
        
        if currentState.country?.isEmpty == true || currentState.country == nil {
            errorDict[.country] = NSLocalizedString("Please select country", comment: "")
        }
        
        if currentState.isStateAvailable && (currentState.stateName?.isEmpty == true || currentState.stateName == nil) {
            errorDict[.state] = NSLocalizedString("Please select state", comment: "")
        }
        
        return errorDict
    }
    
    private func reduceSetCountry(state: State, country: String) -> State {
        var result = state
        
        if country.count > 0 {
            result.validationErrors.removeValue(forKey: .country)
        }
        
        result.country = country
        if country == "US" {
            result.isStateAvailable = true
        } else {
            result.stateName = nil
            result.stateCode = nil
            result.isStateAvailable = false
        }
        let countryState = result.countries.filter { (countryState) -> Bool in
            countryState.code == country
        }
        result.countryStates = countryState.first?.states
        result.locationNotSupported = false
        
        return result
    }
    
    private func reduceEmail(state: State, email: String?) -> State {
        var result = state
        if let email = email, DataValidator.isValid(email: email) {
            result.validationErrors.removeValue(forKey: .email)
        }

        result.email = email
        return result
    }
    
    private func reduceCountryState(state: State, countryState: String?) -> State {
        var result = state
        if let countryState = countryState, countryState.count > 0 {
            result.validationErrors.removeValue(forKey: .state)
        }
        
        result.stateName = countryState
        result.locationNotSupported = false
        
        return result
    }
}
