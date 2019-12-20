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
//  Created by Sergii Iastremskyi on 4/17/19.

import UIKit

import Foundation
import ReactorKit
import RxSwift

class FillPaymentInfoViewReactor: Reactor {
    
    enum PaymentInfoKey {
        case cardNumber
        case expiryDate
        case cvv
        case walletAddress
        case ssn
        case termsAndPolicy
    }
    
    enum Action {
        case enterCardNumber(String?)
        case selectExpiryDate(Date?)
        case enterCVV(String?)
        case enterSNN(String?)
        case enterWallet(String?)
        case setTermsAccepted(Bool)
        case submit
        case setAllImagesUploaded(Bool)
    }
    
    enum Mutation {
        case setCardNumber(String?)
        case setExpiryDate(Date?)
        case setCVV(String?)
        case setSNN(String?)
        case setWallet(String?)
        case setTermsAndPolicyAccepted(Bool)
        case setValidationErrors([PaymentInfoKey: String])
        case setError(Bool)
        case update(Order)
        case setFinished
        case setLoading(Bool)
        case setAllImagesUploaded(Bool)
    }
    
    struct State {
        var cardNumber: String?
        var expiryDate: Date?
        var cvv: String?
        var walletAddress: String?
        var cryptoCurrency: String?
        var ssn: String?
        var isSNNAvailable = false
        var areTermsAndPolicyAccepted: Bool
        var submitTitle: String
        var isEditable = true
        var isNextEnabled = false
        var validationErrors: [PaymentInfoKey: String]
        var error = false
        var isFinished = false
        var isLoading = false
        var rules: [Rule]
        var areAllImagesUploaded = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .enterCardNumber(let cardNumber):
            return Observable.just(Mutation.setCardNumber(cardNumber))
        case .selectExpiryDate(let date):
            return Observable.just(Mutation.setExpiryDate(date))
        case .enterCVV(let cvv):
            return Observable.just(Mutation.setCVV(cvv))
        case .enterSNN(let ssn):
            return .just(.setSNN(ssn))
        case .enterWallet(let wallet):
            return Observable.just(Mutation.setWallet(wallet))
        case .setTermsAccepted(let accepted):
            return Observable.just(Mutation.setTermsAndPolicyAccepted(accepted))
        case .submit:
            return mutateSubmit()
        case .setAllImagesUploaded(let areAllImagesUploaded):
            return .just(Mutation.setAllImagesUploaded(areAllImagesUploaded))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .setCardNumber(let cardNumber):
            state = reduceCardNumber(state: state, cardNumber: cardNumber)
        case .setExpiryDate(let date):
            state = reduceExpiryDate(state: state, expiryDate: date)
        case .setCVV(let cvv):
            state = reduceCVVCode(state: state, cvv: cvv)
        case .setSNN(let ssn):
            state = reduceSNN(state: state, ssn: ssn)
        case .setWallet(let wallet):
            state = reduceWalletAddress(state: state, walletAddress: wallet)
        case .setTermsAndPolicyAccepted(let accepted):
            state = reduceTermsAndPolicyAccepted(state: state, termsAndPolicyAccepted: accepted)
        case .setValidationErrors(let errors):
            state.validationErrors = errors
        case .setError(let error):
            state.error = error
        case .update(let order):
            state = reduceUpdate(state: state, order: order)
        case .setFinished:
            state.isFinished = true
        case let .setLoading(isLoading):
            state.isLoading = isLoading
        case let .setAllImagesUploaded(areAllImagesUploaded):
            state.areAllImagesUploaded = areAllImagesUploaded
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore, rulesStore: RulesStore, isEditing: Bool = false) {
        orderService = serviceProvider.orderService
        paymentService = serviceProvider.paymentService
        self.orderStore = orderStore
        
        let isSNNAvailable = orderStore.order.country == "US"
        let submitTitle = NSLocalizedString(isEditing ? "SAVE" : "NEXT", comment: "")
        
#if DEVELOPMENT
        initialState = State(cardNumber: "5413330000000019".separate(), expiryDate: Date(timeIntervalSinceNow: 10000), cvv: "123", walletAddress: "2Mxx1zJPGfStpi8ANYfmQpAWL6eG9M8Erg1", cryptoCurrency:orderStore.order.cryptoCurrency, ssn: nil, isSNNAvailable: isSNNAvailable, areTermsAndPolicyAccepted: true, submitTitle: submitTitle, isEditable: !isEditing, isNextEnabled: false, validationErrors: [:], error: false, isFinished: false, isLoading: false, rules: rulesStore.rules, areAllImagesUploaded: false)
#else
        initialState = State(cardNumber: nil, expiryDate: nil, cvv: nil, walletAddress: nil, cryptoCurrency:orderStore.order.cryptoCurrency, ssn: nil, isSNNAvailable: isSNNAvailable, areTermsAndPolicyAccepted: false, submitTitle: submitTitle, isEditable: !isEditing, isNextEnabled: false, validationErrors: [:], error: false, isFinished: false, isLoading: false, rules: rulesStore.rules, areAllImagesUploaded: false)
#endif
    }
    
    // MARK: - Implementation
    
    private let orderService: OrderService
    private let paymentService: PaymentService
    private var orderStore: OrderStore
    
    private func mutateSubmit() -> Observable<Mutation> {
        let expiryDateFormatter = DateFormatter()
        expiryDateFormatter.dateFormat = "MM/yy"
        
        var order = orderStore.order
        order.cardNumber = currentState.cardNumber?.replacingOccurrences(of: " ", with: "")
        
        if let expiryDate = currentState.expiryDate {
            order.cardExpiryDate = expiryDateFormatter.string(from: expiryDate)
        } else {
            order.cardExpiryDate = nil
        }
        
        order.cardCVV = currentState.cvv
        order.walletAddress = currentState.walletAddress
        
        if currentState.isSNNAvailable {
            order.ssn = currentState.ssn
        }
        
        order.areTermsAndPolicyAccepted = currentState.areTermsAndPolicyAccepted
        
        orderStore.update(order: order)
        
        if errorDict().count > 0 {
            return .just(.setValidationErrors(errorDict()))
        } else if !currentState.areAllImagesUploaded {
            return .empty()
        } else {
            return .concat(.just(.setLoading(true)),
                paymentService.rx.verifyWallet(order: order).flatMap { [unowned self] _ -> Observable<Mutation> in
                    return self.orderService.rx.sendPaymentData(order: order).do(onNext: { order in
                        self.orderStore.update(order: order)
                    }).map { _ in .setFinished }.catchErrorJustReturn(.setError(true))
                }.catchErrorJustReturn(.setValidationErrors([.walletAddress: NSLocalizedString("Please enter a valid wallet address", comment: "")])),
                .just(.setLoading(false)))
        }
    }
    
    private func errorDict() -> [PaymentInfoKey: String] {
        var errorDict = [PaymentInfoKey: String]()
        
        let cardNumber = currentState.cardNumber?.replacingOccurrences(of: " ", with: "") ?? ""
        if cardNumber.count < Constant.Card.CardNumberLenght || cardNumber.count > Constant.Card.CardNumberLenght {
            errorDict[.cardNumber] = NSLocalizedString("Please enter a valid card number", comment: "")
        }
        
        let cvv = currentState.cvv ?? ""
        if cvv.count < Constant.Card.CvvNumberLenght - 1 || cvv.count  > Constant.Card.CvvNumberLenght {
            errorDict[.cvv] = NSLocalizedString("Please enter valid CVV", comment: "")
        }
        
        if currentState.walletAddress?.isEmpty == true || currentState.walletAddress == nil {
            errorDict[.walletAddress] = NSLocalizedString("Please enter a valid wallet address", comment: "")
        }
        
        let expiryDate = currentState.expiryDate
        if expiryDate == nil || expiryDate! < Date() {
            errorDict[.expiryDate] = NSLocalizedString("Please enter expiry date", comment: "")
        }
        
        if currentState.isSNNAvailable && (currentState.ssn?.isEmpty == true || currentState.ssn == nil || !isValidSSN(currentState.ssn!)) {
            errorDict[.ssn] = NSLocalizedString("Please enter valid SSN", comment: "")
        }
        
        if !currentState.areTermsAndPolicyAccepted {
            errorDict[.termsAndPolicy] = NSLocalizedString("Please agree to ToS", comment: "")
        }
        
        return errorDict
    }
    
    private func reduceUpdate(state: State, order: Order) -> State {
        var result = state
        result.isSNNAvailable = order.country == "US"
        
        return result
    }
    
    private func reduceCardNumber(state: State, cardNumber: String?) -> State {
        var result = state
        if let cardNumber = cardNumber, cardNumber.replacingOccurrences(of: " ", with: "").count == Constant.Card.CardNumberLenght {
            result.validationErrors.removeValue(forKey: .cardNumber)
        }
        
        result.cardNumber = cardNumber
        return result
    }
    
    private func reduceCVVCode(state: State, cvv: String?) -> State {
        var result = state
        if let cvv = cvv, cvv.count >= Constant.Card.CvvNumberLenght - 1 && cvv.count <= Constant.Card.CvvNumberLenght {
            result.validationErrors.removeValue(forKey: .cvv)
        }
        
        result.cvv = cvv
        return result
    }
    
    private func reduceWalletAddress(state: State, walletAddress: String?) -> State {
        var result = state
        if let walletAddress = walletAddress, walletAddress.count > 0 {
            result.validationErrors.removeValue(forKey: .walletAddress)
        }
        
        result.walletAddress = walletAddress
        return result
    }
    
    private func reduceExpiryDate(state: State, expiryDate: Date?) -> State {
        var result = state
        if let expiryDate = expiryDate, expiryDate > Date() {
            result.validationErrors.removeValue(forKey: .expiryDate)
        }
        
        result.expiryDate = expiryDate
        return result
    }
    
    private func reduceSNN(state: State, ssn: String?) -> State {
        var result = state
        if let ssn = ssn, ssn.count > 0 {
            result.validationErrors.removeValue(forKey: .ssn)
        }
        
        result.ssn = ssn
        return result
    }
    
    private func reduceTermsAndPolicyAccepted(state:State, termsAndPolicyAccepted: Bool) -> State {
        var result = state
        if termsAndPolicyAccepted {
            result.validationErrors.removeValue(forKey: .termsAndPolicy)
        }
        
        result.areTermsAndPolicyAccepted = termsAndPolicyAccepted
        return result
    }
    
    private func isValidSSN(_ ssn: String) -> Bool {
        let ssnRegext = "^(?!(000|666|9))\\d{3}-(?!00)\\d{2}-(?!0000)\\d{4}$"
        return ssn.range(of: ssnRegext, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

extension String {
    
    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }
}
