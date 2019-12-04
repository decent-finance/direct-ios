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
//  Created by Ihor Vovk on 6/28/19.

import Foundation
import ReactorKit
import RxSwift

class VerifyPlacementViewReactor: Reactor {
    
    enum Action {
    }
    
    enum Mutation {
        case setPlacementSupported(Bool)
        case setRulesLoaded
        case setCountriesLoaded(Bool)
        case setLoading(Bool)
    }
    
    struct State {
        var isPlacementSupported: Bool?
        var areRulesLoaded = false
        var areCountriesLoaded = false
        var isLoading = false
    }
    
    let initialState: State
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let checkPlacementMutation = Observable.concat(.just(.setLoading(true)),
            merchantService.rx.loadPlacementInfo().flatMap { [weak self] placement -> Observable<Mutation> in
                guard let `self` = self else { return .empty() }
                
                let loadRulesObservable = Observable.combineLatest(placement.ruleIDs.map { self.merchantService.rx.loadRule(id: $0) }).do(onNext: { [weak self] rules in
                    self?.rulesStore.rules = rules
                }).flatMap { _ in Observable.empty() }.concat(Observable.just(Mutation.setRulesLoaded))
                
                let loadCountriesMutation = self.paymentService.rx.loadCountries().do(onNext: { [weak self] countries in
                    self?.countriesStore.countries = countries
                }).map { _ in Mutation.setCountriesLoaded(true) }
                
                return .concat(loadRulesObservable, loadCountriesMutation, .just(.setPlacementSupported(self.merchantService.isPlacementSupported(placement))))
            }.catchErrorJustReturn(.setPlacementSupported(false)),
            .just(.setLoading(false)))
        
        return .merge(mutation, checkPlacementMutation)
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .setPlacementSupported(let isSupported):
            state.isPlacementSupported = isSupported
        case .setRulesLoaded:
            state.areRulesLoaded = true
        case .setCountriesLoaded(let areLoaded):
            state.areCountriesLoaded = areLoaded
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        }

        return state
    }
    
    init(serviceProvider: ServiceProvider, rulesStore: RulesStore, countriesStore: CountriesStore) {
        initialState = State()
        merchantService = serviceProvider.merchantService
        paymentService = serviceProvider.paymentService
        self.rulesStore = rulesStore
        self.countriesStore = countriesStore
    }
    
    // MARK: - Implementation
    
    let merchantService: MerchantService
    let paymentService: PaymentService
    let rulesStore: RulesStore
    let countriesStore: CountriesStore
}
