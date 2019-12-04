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
//  Created by Ihor Vovk on 4/1/19.

import Foundation
import ReactorKit
import RxSwift

class MainViewReactor: Reactor {
    
    enum Page: Int, CaseIterable {
        case getBTC = 0
        case fillInformation
        case paymentConfirmation
        case finish
    }
    
    enum PageContent {
        case baseFillInformation
        case paymentFillInformation
        case additionalFillInformation
        case paymentConfirmation
        case emailConfirmation
        case purchaseSuccess
    }
    
    enum InfoContent {
        case generalError
        case serviceDown
        case verificationRejected
        case processingRejected
        case locationNotSupported
        case verificationInProgress
        case paymentRefunded
        
        var isError: Bool {
            switch self {
            case .verificationInProgress, .paymentRefunded:
                return false
            default:
                return true
            }
        }
    }
    
    enum Action {
        case finish(PageContent)
    }
    
    enum Mutation {
        case setPage(Page)
        case setPageContent(PageContent)
        case setInfoContent(InfoContent?)
        case setLoading(Bool)
    }
    
    struct State {
        var page: Page
        var pageContent: PageContent
        var isNextHidden: Bool
        var cryptoCurrency: String? = nil
        var fiatCurrency: String? = nil
        var infoContent: InfoContent? = nil
        var orderId: String? = nil
        var isLoading = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .finish(pageContent):
            return mutateFinish(pageContent: pageContent)
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let statusMutation = orderStore.rx_order.filter { $0.orderID != nil }.flatMapFirst { [unowned self] order in
            self.orderService.rx.subscribeOrderUpdates(order: order)
        }.distinctUntilChanged { $0.status == $1.status }.flatMap { [unowned self] order -> Observable<Mutation> in
            guard let status = order.status else { return .empty() }
            self.orderStore.update(order: order)
            
            switch status {
            case .new, .uncompleted:
                return .concat(.just(.setLoading(false)), .just(.setPageContent(.paymentFillInformation)))
            case .verificationReady, .ivsReady:
                return self.orderService.rx.sendCardDataToVerification(order: self.orderStore.order).flatMap { _ in Observable.empty() }.catchErrorJustReturn(.setInfoContent(.serviceDown))
            case .verificationRejected, .ivsRejected:
                return .just(.setInfoContent(.verificationRejected))
            case .verificationFailed, .ivsFailed:
                return .just(.setInfoContent(.serviceDown))
            case .processingAcknowledge, .pssWaitData:
                return .concat(.just(.setLoading(false)), .just(.setPageContent(.additionalFillInformation)))
            case .processingReady, .pssReady:
                return self.orderService.rx.sendCardDataToProcessing(order: self.orderStore.order).flatMap { _ in Observable.empty() }.catchErrorJustReturn(.setInfoContent(.serviceDown))
            case .processingRejected, .pssRejected:
                return .just(.setInfoContent(.processingRejected))
            case .processingFailed, .pssFailed:
                return .just(.setInfoContent(.serviceDown))
            case .processing3ds, .pss3dsRequired:
                return .concat(.just(.setLoading(false)), .just(.setPageContent(.paymentConfirmation)))
            case .refunded:
                return .concat(.just(.setLoading(false)), .just(.setInfoContent(.paymentRefunded)))
            case .emailConfirmation, .waitingForConfirmation:
                return .concat(.just(.setLoading(false)), .just(.setPageContent(.emailConfirmation)))
            case .cryptoSending, .completed:
                return .concat(.just(.setLoading(false)), .just(.setPageContent(.purchaseSuccess)))
            case .cryptoSent, .settled, .finished:
                return .empty()
            case .crashed:
                return .just(.setInfoContent(.serviceDown))
            case .rejected:
                return .just(.setInfoContent(.generalError))
            default:
                return .empty()
            }
        }.takeUntil(.inclusive) { mutation -> Bool in
            if case .setInfoContent(let content) = mutation, content?.isError == true {
                return true
            } else {
                return false
            }
        }
        
        return .merge(mutation, statusMutation)
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        state.orderId = orderStore.order.orderID
        
        switch mutation {
        case let .setPage(page):
            state.page = page
        case let .setPageContent(pageContent):
            state = reduceSetPageContent(state: state, pageContent: pageContent)
        case let .setInfoContent(infoContent):
            state.infoContent = infoContent
            state.isLoading = false
        case let .setLoading(isLoading):
            state.isLoading = isLoading
        }
        
        return state
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
        
        let order = orderStore.order
        initialState = State(page: .fillInformation, pageContent: .baseFillInformation, isNextHidden: false, cryptoCurrency: order.cryptoCurrency, fiatCurrency: order.fiatCurrency, infoContent: nil, orderId: order.orderID, isLoading: false)
        
        orderService.sendBuyEvent(order: orderStore.order)
    }
    
    // MARK: - Implementation
    
    private let orderService: OrderService
    private let orderStore: OrderStore
    
    private func mutateFinish(pageContent: PageContent) -> Observable<Mutation> {
        switch pageContent {
        case .baseFillInformation, .additionalFillInformation, .paymentConfirmation, .emailConfirmation:
            return .just(.setLoading(true))
        case .paymentFillInformation:
            return .just(.setInfoContent(.verificationInProgress))
        default:
            return .empty()
        }
    }
    
    private func reduceSetPageContent(state: State, pageContent: PageContent) -> State {
        var result = state
        result.pageContent = pageContent
        result.infoContent = nil
        
        switch pageContent {
        case .baseFillInformation, .paymentFillInformation, .additionalFillInformation:
            result.page = .fillInformation
        case .paymentConfirmation, .emailConfirmation:
            result.page = .paymentConfirmation
        case .purchaseSuccess:
            result.page = .finish
        }
        
        result.isNextHidden = [.additionalFillInformation, .paymentConfirmation, .emailConfirmation].contains(pageContent)
    
        return result
    }
    
    func title(page: Page) -> String {
        switch page {
        case .getBTC:
            let order = orderStore.order
            if let cryptoAmount = order.cryptoAmount, let cryptoCurrency = order.cryptoCurrency, let fiatAmount = order.fiatAmount, let fiatCurrency = order.fiatCurrency  {
                return String(format:NSLocalizedString("Get %@ %@ for %@ %@", comment: ""), cryptoAmount, cryptoCurrency, fiatAmount, fiatCurrency)
            }
            return ""
        case .fillInformation:
            return NSLocalizedString("Fill Information", comment: "")
        case .paymentConfirmation:
            return NSLocalizedString("Payment Confirmation", comment: "")
        case .finish:
            return NSLocalizedString("Finish", comment: "")
        }
    }
    
    func purchaseInfoTitle() -> String {
        let order = orderStore.order
        if let cryptoAmount = order.cryptoAmount, let cryptoCurrency = order.cryptoCurrency, let fiatAmount = order.fiatAmount, let fiatCurrency = order.fiatCurrency  {
            return String(format:NSLocalizedString("Buy %@ %@ for %@ %@", comment: ""), cryptoAmount, cryptoCurrency, fiatAmount, fiatCurrency)
        }
        return ""
    }
}
