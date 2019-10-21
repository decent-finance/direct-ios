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
//  Created by Ihor Vovk on 4/18/19.

import Foundation
import ReactorKit
import RxSwift

private enum BlockchainLinkType: String {
    case eth = "ETH"
    case bch = "BCH"
    case btc = "BTC"
    
    var blockchainLink: String {
        switch self {
        case .eth:
            return "https://etherscan.io/tx/"
        case .bch:
            return "https://blockchair.com/bitcoin-cash/transaction/"
        case .btc:
            return "https://www.blockchain.com/btc/tx/"
        }
    }
}

class PurchaseSuccessViewReactor: Reactor {
    
    enum Action {
        case submit
    }
    
    enum Mutation {
        case setTxID(String?)
        case setFinished
    }
    
    struct State {
        var cryptoAmount: String
        var cryptoCurrency: String
        var fiatAmount: String
        var fiatCurrency: String
        var comission: String
        var orderID: String
        var txID: String?
        var txIDLink: String?
        var isFinished = false
    }
    
    let initialState: State
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .submit:
            return Observable.just(Mutation.setFinished)
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return .merge(mutation, orderStore.rx_order.map { .setTxID($0.txID) })
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .setTxID(let txID):
            state = reduceTextID(state: state, txID: txID)
        case .setFinished:
            state.isFinished = true
        }
        
        return state
    }
    
    init(orderStore: OrderStore) {
        self.orderStore = orderStore
        
        let order = orderStore.order
        initialState = State(cryptoAmount: order.cryptoAmount ?? "", cryptoCurrency: order.cryptoCurrency ?? "", fiatAmount: order.fiatAmount ?? "", fiatCurrency: order.fiatCurrency ?? "", comission: "", orderID: order.orderID ?? "", txID: nil, txIDLink: nil, isFinished: false)
    }
    
    // MARK: - Implementation
    
    let orderStore: OrderStore
    
    private func reduceTextID(state: State, txID: String?) -> State {
        var result = state
        result.txID = txID
        if let txID = txID, txID.count > 0 {
            switch state.cryptoCurrency {
            case BlockchainLinkType.eth.rawValue:
                result.txIDLink = BlockchainLinkType.eth.blockchainLink + txID
            case BlockchainLinkType.btc.rawValue:
                result.txIDLink = BlockchainLinkType.btc.blockchainLink + txID
            case BlockchainLinkType.bch.rawValue:
                result.txIDLink = BlockchainLinkType.bch.blockchainLink + txID
            default:
                result.txIDLink = nil
            }
        }

        return result
    }
}
