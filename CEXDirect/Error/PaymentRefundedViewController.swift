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
//  Created by Ihor Vovk on 11/22/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

class PaymentRefundedViewController: BaseErrorViewController, StoryboardView {
    
    var disposeBag = DisposeBag()
    
    func bind(reactor: PaymentRefundedViewReactor) {
        reactor.state.map { UIImage(named: $0.currencyImageName ?? "", in: Bundle(for: type(of: self)), compatibleWith: nil) }
            .bind(to: currencyImageView.rx.image)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.returnedAmount }
            .bind(to: returnedAmountLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.card }
            .bind(to: cardLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var currencyImageView: UIImageView!
    @IBOutlet private weak var returnedAmountLabel: UILabel!
    @IBOutlet private weak var cardLabel: UILabel!
}
