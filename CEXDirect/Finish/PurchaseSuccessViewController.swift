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

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol PurchaseSuccessViewControllerDelegate: class {
    
    var nextTap: RxCocoa.ControlEvent<Void> { get }
    var submitionFinishedSubject: PublishSubject<Void> { get }
}

class PurchaseSuccessViewController: UIViewController, StoryboardView {
    
    var delegate: PurchaseSuccessViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    private let tapGesture = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txIDLabel.addGestureRecognizer(tapGesture)
    }
    
    func bind(reactor: PurchaseSuccessViewReactor) {
        reactor.state.map { $0.cryptoAmount + " " + $0.cryptoCurrency }
            .bind(to: cryptoAmountLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.fiatAmount + " " + $0.fiatCurrency }
            .bind(to: fiatAmountLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.comission }
            .bind(to: comissionLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.txID }.map {
            let attribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
            let attributedString = NSAttributedString(string: $0 ?? "", attributes: attribute)
            return attributedString }
            .bind(to: txIDLabel.rx.attributedText)
            .disposed(by: disposeBag)
        
        reactor.state.map { if let txID = $0.txID, txID.count > 0 {return true}
            return false }
            .bind(to: txIDActivityIndicatorView.rx.isHidden)
            .disposed(by: disposeBag)
        
        tapGesture.rx.event.bind(onNext: { recognizer in
            if let txIDLink = reactor.currentState.txIDLink, txIDLink.count > 0, let url = URL(string: txIDLink), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.cryptoCurrency }.map { UIImage(named: "ic_coin_\($0.lowercased())", in: Bundle(for: type(of: self)), compatibleWith: nil) }
            .bind(to: coinImageView.rx.image)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isFinished }.distinctUntilChanged().filter { $0 }.subscribe(onNext: { [unowned self] isFinished in
            self.delegate?.submitionFinishedSubject.onNext(())
        }).disposed(by: disposeBag)
        
        delegate?.nextTap.takeUntil(reactor.state.filter { $0.isFinished })
            .map { Reactor.Action.submit }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    @IBOutlet private weak var cryptoAmountLabel: UILabel!
    @IBOutlet private weak var fiatAmountLabel: UILabel!
    @IBOutlet private weak var comissionLabel: UILabel!
    @IBOutlet private weak var txIDLabel: UILabel!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var coinImageView: UIImageView!
    @IBOutlet private weak var txIDActivityIndicatorView: UIActivityIndicatorView!
}
