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

class OrderAmountViewReactor: Reactor {
    
    enum Action {
        case enableEditingCrypto
        case enterCryptoAmount(String?)
        case selectCryptoCurrency(String)
        case enterFiatAmount(String?)
        case selectFiatCurrency(String)
        case selectFiatPopularAmount(index: Int)
        case buy
    }
    
    enum Mutation {
        case setUp([CurrencyConversion], [CurrencyPrecision])
        case setCryptoEditingEnabled(Bool)
        case setCryptoAmount(String?, [CurrencyConversion], [CurrencyPrecision])
        case setCryptoCurrency(String?, [CurrencyConversion], [CurrencyPrecision])
        case setCryptoError(String?)
        case setFiatAmount(String?, [CurrencyConversion], [CurrencyPrecision])
        case setFiatCurrency(String, [CurrencyConversion], [CurrencyPrecision])
        case setFiatError(String?)
        case selectFiatPopularAmount(index: Int, [CurrencyConversion], [CurrencyPrecision])
        case validateBuy([CurrencyPrecision])
    }
    
    struct State {
        var isCryptoEditingEnabled = false
        var fiatCurrencyPrecision: Int? = nil
        var cryptoCurrencyPrecision: Int? = nil
        
        var cryptoAmount: String? = nil
        var cryptoCurrency: String? = nil
        var cryptoError: String? = nil
        var allCryptoCurrencies: [String]? = nil
        var cryptoPopularAmounts: [String]? = nil
        
        var fiatAmount: String? = nil
        var fiatCurrency: String? = nil
        var fiatError: String? = nil
        var allFiatCurrencies: [String]? = nil
        var fiatPopularAmounts: [String]? = nil
        
        var isFinished: Bool = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .enableEditingCrypto:
            return Observable.just(Mutation.setCryptoEditingEnabled(true))
        case let .enterCryptoAmount(amount):
            return Observable.combineLatest(currencyConversionsObservable, currencyPrecisionsObservable).take(1).map { .setCryptoAmount(amount, $0, $1) }
        case let .selectCryptoCurrency(currency):
            return Observable.combineLatest(currencyConversionsObservable, currencyPrecisionsObservable).take(1).map { .setCryptoCurrency(currency, $0, $1) }
        case let .enterFiatAmount(amount):
            return Observable.combineLatest(currencyConversionsObservable, currencyPrecisionsObservable).take(1).map { .setFiatAmount(amount, $0, $1) }
        case let .selectFiatCurrency(currency):
            return Observable.combineLatest(currencyConversionsObservable, currencyPrecisionsObservable).take(1).map { .setFiatCurrency(currency, $0, $1) }
        case let .selectFiatPopularAmount(index):
            return Observable.combineLatest(currencyConversionsObservable, currencyPrecisionsObservable).take(1).map { .selectFiatPopularAmount(index: index, $0, $1) }
        case .buy:
            return mutateBuy()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        state.isFinished = false
        
        switch mutation {
        case let .setUp(currencyConversions, currencyPrecisions):
            state = reduceSetUp(state: state, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        case let .setCryptoEditingEnabled(isEnabled):
            state.isCryptoEditingEnabled = isEnabled
        case let .setCryptoAmount(amount, currencyConversions, currencyPrecisions):
            state = reduceSetCryptoAmount(state: state, amount: amount, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        case let .setCryptoCurrency(currency, currencyConversions, currencyPrecisions):
            state = reduceSetCryptoCurrency(state: state, currency: currency, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        case let .setCryptoError(error):
            state.cryptoError = error
        case let .setFiatAmount(amount, currencyConversions, currencyPrecisions):
            state = reduceSetFiatAmount(state: state, amount: amount, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        case let .setFiatCurrency(currency, currencyConversions, currencyPrecisions):
            state = reduceSetFiatCurrency(state: state, currency: currency, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        case let .setFiatError(error):
            state.fiatError = error
        case let .selectFiatPopularAmount(index, currencyConversions, currencyPrecisions):
            state = reduceSelectFiatPopularAmount(state: state, index: index, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        case .validateBuy(let currencyPrecisions):
            state = reduceValidateBuy(state: state, currencyPrecisions: currencyPrecisions)
        }
        
        return state
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let setUpObservable = Observable.combineLatest(currencyConversionsObservable, currencyPrecisionsObservable).map { (currencyConversions, currencyPrecisions) -> Mutation in
            return .setUp(currencyConversions, currencyPrecisions)
        }
        
        return Observable.merge(mutation, setUpObservable)
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        paymentService = serviceProvider.paymentService
        merchantService = serviceProvider.merchantService
        self.orderStore = orderStore
        
        var state = State()
        state.fiatAmount = orderStore.order.fiatAmount
        
        initialState = state
        
        currencyConversionsObservable = paymentService.rx.subscribeCurrencies().share(replay: 1)
        currencyPrecisionsObservable = merchantService.rx.loadCurrencyPrecisions().share(replay: 1)
        
        serviceProvider.orderService.sendOpenedEvent(order: orderStore.order)
    }
    
    // MARK: - Implementation
    
    private let paymentService: PaymentService
    private let merchantService: MerchantService
    private var orderStore: OrderStore
    
    private let currencyConversionsObservable: Observable<[CurrencyConversion]>
    private let currencyPrecisionsObservable: Observable<[CurrencyPrecision]>
    
    private func mutateBuy() -> Observable<Mutation> {
        var order = self.orderStore.order
        order.cryptoAmount = currentState.cryptoAmount
        order.cryptoCurrency = currentState.cryptoCurrency
        order.fiatAmount = currentState.fiatAmount
        order.fiatCurrency = currentState.fiatCurrency
        
        self.orderStore.order = order
        
        return currencyPrecisionsObservable.take(1).map { .validateBuy($0) }
    }
    
    private func reduceSetUp(state: State, currencyConversions: [CurrencyConversion], currencyPrecisions: [CurrencyPrecision]) -> State {
        var result = state
        
        result.allFiatCurrencies = currencyConversions.compactMap { $0.fiat }.removingDuplicates()
        if result.fiatCurrency == nil || result.allFiatCurrencies?.contains(result.fiatCurrency!) == false {
            result.fiatCurrency = result.allFiatCurrencies?.first
        }
        
        if let fiatCurrency = result.fiatCurrency {
            result.allCryptoCurrencies = cryptoCurrenciesForFiat(fiatCurrency, currencyConversions: currencyConversions)
        }
        
        if result.cryptoCurrency == nil || result.allCryptoCurrencies?.contains(result.cryptoCurrency!) == false {
            result.cryptoCurrency = result.allCryptoCurrencies?.first
        }
        
        if let currencyConversion = currencyConversions.first(where: { $0.fiat == result.fiatCurrency && $0.crypto == result.cryptoCurrency }) {
            if let fiatPopularAmounts = currencyConversion.fiatPopularValues {
                if result.fiatAmount == nil || result.fiatAmount?.count == 0 {
                    result.fiatAmount = fiatPopularAmounts.first
                    result.fiatPopularAmounts = Array(fiatPopularAmounts.dropFirst())
                } else {
                    result.fiatPopularAmounts = fiatPopularAmounts
                }
            }
        }
        
        result.cryptoCurrencyPrecision = currencyPrecisions.filter {$0.currency == result.cryptoCurrency}.first?.visiblePrecision
        result.fiatCurrencyPrecision = currencyPrecisions.filter {$0.currency == result.fiatCurrency}.first?.visiblePrecision
        
        result = reduceSetFiatAmount(state: result, amount: result.fiatAmount, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        
        return result
    }
    
    private func reduceSelectFiatPopularAmount(state: State, index: Int, currencyConversions: [CurrencyConversion], currencyPrecisions: [CurrencyPrecision]) -> State {
        if let fiatPopularAmounts = state.fiatPopularAmounts, index < fiatPopularAmounts.count {
            return reduceSetFiatAmount(state: state, amount: fiatPopularAmounts[index], currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
        } else {
            return state
        }
    }
    
    private func reduceSetCryptoAmount(state: State, amount: String?, currencyConversions: [CurrencyConversion], currencyPrecisions: [CurrencyPrecision]) -> State {
        guard let currencyConversion = currencyConversions.first(where: { currencyConversion -> Bool in
            return currencyConversion.crypto == state.cryptoCurrency && currencyConversion.fiat == state.fiatCurrency
        }), let currencyPrecision = currencyPrecisions.first(where: { currencyPrecision -> Bool in
            return currencyPrecision.type == "fiat" && currencyPrecision.currency == state.fiatCurrency
        }) else { return state }
        if state.cryptoAmount == amount {
            return state
        }
        
        var result = state
        result.cryptoAmount = amount
        if let amount = amount, let precision = currencyPrecision.visiblePrecision {
            result.fiatAmount = currencyConversion.convertToFiat(cryptoAmount: amount, precision: precision, roundRule: currencyPrecision.visibleRoundRule)
            if let cryptoAmount = result.cryptoAmount, let cryptoAmountDecimal = Decimal(string: cryptoAmount, locale: Locale.current), cryptoAmountDecimal == 0 {
                result.fiatAmount = "0"
            }
        } else {
            result.fiatAmount = nil
        }
        
        if result.cryptoError != nil || result.fiatError != nil {
            result = reduceValidateAmounts(state: result, currencyPrecisions: currencyPrecisions)
        }
        
        return result
    }
    
    private func reduceSetFiatAmount(state: State, amount: String?, currencyConversions: [CurrencyConversion], currencyPrecisions: [CurrencyPrecision]) -> State {
        guard let currencyConversion = currencyConversions.first(where: { currencyConversion -> Bool in
            return currencyConversion.crypto == state.cryptoCurrency && currencyConversion.fiat == state.fiatCurrency
        }), let currencyPrecision = currencyPrecisions.first(where: { currencyPrecision -> Bool in
            return currencyPrecision.type == "crypto" && currencyPrecision.currency == state.cryptoCurrency
        }) else { return state }
        
        var result = state
        result.fiatAmount = amount
        if let amount = amount, let precision = currencyPrecision.visiblePrecision {
            result.cryptoAmount = currencyConversion.convertToCrypto(fiatAmount: amount, precision: precision, roundRule: currencyPrecision.visibleRoundRule)
            if let cryptoAmount = result.cryptoAmount, let cryptoAmountDecimal = Decimal(string: cryptoAmount, locale: Locale.current), cryptoAmountDecimal < 0 {
                result.cryptoAmount = "0"
            }
        } else {
            result.cryptoAmount = nil
        }
        
        if result.cryptoError != nil || result.fiatError != nil {
            result = reduceValidateAmounts(state: result, currencyPrecisions: currencyPrecisions)
        }
        
        result.fiatPopularAmounts = currencyConversion.fiatPopularValues
        
        return result
    }
    
    private func reduceSetFiatCurrency(state: State, currency: String?, currencyConversions: [CurrencyConversion], currencyPrecisions: [CurrencyPrecision]) -> State {
        var result = state
        result.fiatCurrency = currency
        if let currency = currency {
            result.allCryptoCurrencies = cryptoCurrenciesForFiat(currency, currencyConversions: currencyConversions)
        } else {
            result.allCryptoCurrencies = nil
        }
    
        if let cryptoCurrency = result.cryptoCurrency, let allCryptoCurrencies = result.allCryptoCurrencies {
            if !allCryptoCurrencies.contains(cryptoCurrency) {
                result.cryptoCurrency = allCryptoCurrencies.first
            }
        }
        
        result.fiatCurrencyPrecision = currencyPrecisions.filter {$0.currency == currency}.first?.visiblePrecision
        
        return reduceSetFiatAmount(state: result, amount: state.fiatAmount, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
    }
    
    private func reduceSetCryptoCurrency(state: State, currency: String?, currencyConversions: [CurrencyConversion], currencyPrecisions: [CurrencyPrecision]) -> State {
        var result = state
        result.cryptoCurrency = currency
        result.cryptoCurrencyPrecision = currencyPrecisions.filter {$0.currency == currency}.first?.visiblePrecision
        
        return reduceSetFiatAmount(state: result, amount: state.fiatAmount, currencyConversions: currencyConversions, currencyPrecisions: currencyPrecisions)
    }
    
    private func reduceValidateBuy(state: State, currencyPrecisions: [CurrencyPrecision]) -> State {
        var result = reduceValidateAmounts(state: state, currencyPrecisions: currencyPrecisions)
        if result.cryptoError == nil && result.fiatError == nil {
            result.isFinished = true
        }
        
        return result
    }
    
    private func reduceValidateAmounts(state: State, currencyPrecisions: [CurrencyPrecision]) -> State {
        guard let cryptoAmount = state.cryptoAmount, let cryptoCurrencyPrecision = currencyPrecisions.first(where: { $0.currency == state.cryptoCurrency }), let cryptoMinLimit = cryptoCurrencyPrecision.minLimit, let cryptoMinLimitDecimal = Decimal(string: cryptoMinLimit), let cryptoMaxLimit = cryptoCurrencyPrecision.maxLimit, let cryptoMaxLimitDecimal = Decimal(string: cryptoMaxLimit), let fiatAmount = state.fiatAmount, let fiatCurrencyPrecision = currencyPrecisions.first(where: { $0.currency == state.fiatCurrency }), let fiatMinLimit = fiatCurrencyPrecision.minLimit, let fiatMinLimitDecimal = Decimal(string: fiatMinLimit), let fiatMaxLimit = fiatCurrencyPrecision.maxLimit, let fiatMaxLimitDecimal = Decimal(string: fiatMaxLimit) else { return state }
        
        var result = state
        
        if let cryptoAmountDecimal = Decimal(string: cryptoAmount, locale: Locale.current), let fiatAmountDecimal = Decimal(string: fiatAmount, locale: Locale.current) {
            if cryptoAmountDecimal < cryptoMinLimitDecimal {
                result.cryptoError = String(format: NSLocalizedString("Minimal sale volume is %@", comment: ""), cryptoMinLimit)
            } else if cryptoMaxLimitDecimal > 0, cryptoAmountDecimal > cryptoMaxLimitDecimal {
                result.cryptoError = String(format: NSLocalizedString("You can spend up to %@", comment: ""), cryptoMaxLimit)
            } else {
                result.cryptoError = nil
            }
            
            if fiatAmountDecimal < fiatMinLimitDecimal {
                result.fiatError = String(format: NSLocalizedString("Minimal purchase is %@", comment: ""), fiatMinLimit)
            } else if fiatMaxLimitDecimal > 0, fiatAmountDecimal > fiatMaxLimitDecimal {
                result.fiatError = String(format: NSLocalizedString("You can spend up to %@", comment: ""), fiatMaxLimit)
            } else {
                result.fiatError = nil
            }
        } else {
            result.cryptoError = String(format: NSLocalizedString("Please enter an amount", comment: ""))
            result.fiatError = String(format: NSLocalizedString("Please enter an amount", comment: ""))
        }
        
        if result.cryptoError != nil {
            result.isCryptoEditingEnabled = true
        }
        
        return result
    }
    
    private func cryptoCurrenciesForFiat(_ fiat: String, currencyConversions: [CurrencyConversion]) -> [String] {
        return currencyConversions.filter { $0.fiat == fiat }.compactMap { $0.crypto }.reduce([], { (result, crypto) -> [String] in
            result + [crypto]
        }).removingDuplicates()
    }
}
