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

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol OrderAmountViewControllerDelegate: class {
    
    func setUpFooterViewController(_ controller: FooterViewController)
    func setUpVerifyPlacementViewController(_ controller: VerifyPlacementViewController, delegate: VerifyPlacementViewControllerDelegate)
    func orderAmountViewControllerDidTapBuy(_ controller: OrderAmountViewController)
    func orderAmountViewControllerDidTapExit(_ controller: OrderAmountViewController)
}

class OrderAmountViewController: UIViewController, StoryboardView {
    
    weak var delegate: OrderAmountViewControllerDelegate?
    var context: AnyObject?
    
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logo = UIImage(named: "logo", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let imageView = UIImageView(image: logo)
        navigationItem.titleView = imageView
        
        fiatAmountTextField.delegate = self
        cryptoAmountTextField.delegate = self
        
        verifyPlacementContainerView.isHidden = false
        self.hideKeyboardWhenTappedAround()
    }
    
    func bind(reactor: OrderAmountViewReactor) {
        reactor.state.map { String(format: NSLocalizedString("Purchase %@ for %@", comment: ""), $0.cryptoCurrency ?? "", $0.fiatCurrency ?? "") }
            .bind(to: purchaseLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state.map { $0.isCryptoEditingEnabled }
            .bind(to: cryptoButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { !$0.isCryptoEditingEnabled }
            .bind(to: cryptoAmountTextField.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { String(format:NSLocalizedString("Get %@ %@", comment: ""), $0.cryptoAmount ?? "", $0.cryptoCurrency ?? "") }
            .bind(to: cryptoButton.rx.title())
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.cryptoAmount }
            .bind(to: cryptoAmountTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.cryptoCurrency }
            .bind(to: cryptoAmountTextField.rx.buttonTitle())
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.cryptoError }.subscribe(onNext: { [unowned self] error in
            self.cryptoAmountTextField.error = error
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.fiatAmount }
            .bind(to: fiatAmountTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.fiatCurrency }
            .bind(to: fiatAmountTextField.rx.buttonTitle())
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.fiatError }.subscribe(onNext: { [unowned self] error in
            self.fiatAmountTextField.error = error
        }).disposed(by: disposeBag)
        
        reactor.state.subscribe(onNext: { [weak self] state in
            guard let `self` = self, let popularAmounts = state.fiatPopularAmounts, let fiatCurrency = state.fiatCurrency else { return }
            for (i, button) in self.fiatPopularAmountButtons.enumerated() {
                if i < popularAmounts.count {
                    button.title = popularAmounts[i] + " " + fiatCurrency
                    button.isHidden = false
                } else {
                    button.isHidden = true
                }
            }
        }).disposed(by: disposeBag)
        
        reactor.state.filter { $0.isFinished }.subscribe(onNext: { [unowned self] _ in
            self.delegate?.orderAmountViewControllerDidTapBuy(self)
        }).disposed(by: disposeBag)
        
        cryptoButton.rx.tap.map { Reactor.Action.enableEditingCrypto }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        cryptoAmountTextField.rx.text.skip(1).map { Reactor.Action.enterCryptoAmount($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        fiatAmountTextField.rx.text.skip(1).map { Reactor.Action.enterFiatAmount($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        pastedFiatAmountSubject.map { Reactor.Action.enterFiatAmount($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        pastedCryptoAmountSubject.map { Reactor.Action.enterCryptoAmount($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedFiatCurrencySubject.map { Reactor.Action.selectFiatCurrency($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedCryptoCurrencySubject.map { Reactor.Action.selectCryptoCurrency($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        for (index, fiatPopularAmountButton) in fiatPopularAmountButtons.enumerated() {
            fiatPopularAmountButton.rx.tap.map { Reactor.Action.selectFiatPopularAmount(index: index) }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
        
        buyButton.rx.tap.throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.buy }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "verifyPlacement", let checkPlacementViewController = segue.destination as? VerifyPlacementViewController {
            delegate?.setUpVerifyPlacementViewController(checkPlacementViewController, delegate: self)
        }
    }
    
    private func setUpFooterView() {
        let footerController = FooterViewController.init(nibName: String(describing: FooterViewController.self), bundle: Bundle(for: type(of: self)))
        delegate?.setUpFooterViewController(footerController)
        self.cd_addChildViewController(footerController, containerView: footerView)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var purchaseLabel: UILabel!
    @IBOutlet private weak var cryptoButton: CDButton!
    @IBOutlet private weak var cryptoAmountTextField: CDAmountTextField!
    @IBOutlet private weak var fiatAmountTextField: CDAmountTextField!
    @IBOutlet private var fiatPopularAmountButtons: [CDButton]!
    @IBOutlet private weak var buyButton: CDButton!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var verifyPlacementContainerView: UIView!
    
    private let selectedFiatCurrencySubject = PublishSubject<String>()
    private let selectedCryptoCurrencySubject = PublishSubject<String>()
    private let pastedCryptoAmountSubject = PublishSubject<String>()
    private let pastedFiatAmountSubject = PublishSubject<String>()
    private let currencyDataSource = CurrencyListDataSource()
}

extension OrderAmountViewController : CDAmountTextFieldDelegate {
    func changeCurrency(_ textField: CDAmountTextField) {
        if let currencyPickerViewController = UIStoryboard(name: "CDPickerViewController", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CDPickerViewController,
            let sheetContainerController = UIStoryboard(name: "CEXBottomSheetContainer", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CEXBottomSheetContainerController {
            currencyPickerViewController.delegate = self
            currencyPickerViewController.selectedCode = textField.button.titleLabel?.text
            currencyPickerViewController.isCountryPicker = false
            currencyPickerViewController.selectedCurrencyTextField = textField
            if let reactor = reactor {
                let currencyArray = textField == fiatAmountTextField ? reactor.currentState.allFiatCurrencies : reactor.currentState.allCryptoCurrencies
                currencyPickerViewController.cdPickerArray = currencyDataSource.currencyArray(currencyArray ?? [])
                currencyPickerViewController.isFiatPicker = currencyDataSource.isSymbolFiat(symbol: currencyArray?.first)
            }

            sheetContainerController.setup(contentViewController: currencyPickerViewController)
            present(sheetContainerController, animated: true, completion: nil)
        }
    }
    
    func textField(_ textField: CDAmountTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let currencyPrecision = textField == fiatAmountTextField ? reactor?.currentState.fiatCurrencyPrecision : reactor?.currentState.cryptoCurrencyPrecision {
            if let text = textField.text, let index = text.replaceComma().firstIndex(of: ".") {
                let distance = text.distance(from: text.startIndex, to: index)
                return text.count - distance <= currencyPrecision || string.count == 0
            }
            
            if string.count > 1, let index = string.replaceComma().firstIndex(of: ".")  {
                let distance = string.distance(from: string.startIndex, to: index)
                if string.count > distance + currencyPrecision + 1 {
                    let index = string.index(string.startIndex, offsetBy: distance + currencyPrecision + 1)
                    let text = String(string.prefix(upTo: index))
                    textField == fiatAmountTextField ? pastedFiatAmountSubject.onNext(text) : pastedCryptoAmountSubject.onNext(text)
                    return false
                }
            }
        }
        
        return true
    }
}

extension OrderAmountViewController: CDPickerDelegate {
    
    func selectedCurrencyValue(textField: CDAmountTextField?, dict: Dictionary<String, String>) {
        
        guard let currencyCode = dict[CDPickerEnum.code.rawValue] else {
            return
        }
        
        if textField == fiatAmountTextField {
            selectedFiatCurrencySubject.onNext(currencyCode)
        } else {
            selectedCryptoCurrencySubject.onNext(currencyCode)
        }
    }
    
    func selectedPickerValue(button: CDPickerButton, dict: Dictionary<String, String>) {}
}

extension OrderAmountViewController: VerifyPlacementViewControllerDelegate {
    
    func verifyPlacementViewController(_ viewController: VerifyPlacementViewController, didVerifySupported isSupported: Bool) {
        if isSupported {
            verifyPlacementContainerView.isHidden = true
            setUpFooterView()
        }
    }
    
    func verifyPlacementViewControllerDidTapExit(_ viewController: VerifyPlacementViewController) {
        delegate?.orderAmountViewControllerDidTapExit(self)
    }
}
