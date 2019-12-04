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
import ReactorKit
import RxSwift
import RxCocoa

protocol FillPaymentInfoViewControllerDelegate: class {
    
    var nextEnabled: RxCocoa.Binder<Bool> { get }
    var nextTap: RxCocoa.ControlEvent<Void> { get }
    var submitionFinishedSubject: PublishSubject<Void> { get }
    var loadingSubject: BehaviorSubject<Bool> { get }
    
    func scrollToErrorField(field: UIView)
    func didTapRule(didTapRule rule: String)
    func showServiceDownError()
}

class FillPaymentInfoViewController: UIViewController, StoryboardView {

    var disposeBag = DisposeBag()
    weak var delegate: FillPaymentInfoViewControllerDelegate?
    typealias Reactor = FillPaymentInfoViewReactor
    
    var uploadPhotoViewController: UploadPhotoViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        expiryDateTextField.delegate = self
        cardNumberTextField.delegate = self
        cvvTextField.delegate = self
        walletTextField.delegate = self
        ssnTextField.delegate = self
        agreeCheckbox.delegate = self
        
        if let uploadPhotoViewController = uploadPhotoViewController {
            uploadPhotoViewController.delegate = self
            cd_addChildViewController(uploadPhotoViewController, containerView: documentsView)
            documentsView.backgroundColor = .clear
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editBaseInformation", let controller = segue.destination as? FillBaseInfoViewController {
            controller.view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func bind(reactor: Reactor) {
        reactor.state.map { $0.cardNumber }
            .bind(to: cardNumberTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.expiryDate }.map { [unowned self] date -> String? in
            if let date = date {
                return self.expiryDateFormatter.string(from: date)
            } else {
                return nil
            }
        }.bind(to: expiryDateTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.cvv }
            .bind(to: cvvTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.rules }.subscribe(onNext: { [unowned self] rules in
            self.agreeCheckbox.message = self.agreeCheckbox.configLabelWithRules(rules)
            self.agreeCheckbox.addLinkWithRules(rules)
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.ssn }
            .bind(to: ssnTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.walletAddress }
            .bind(to: walletTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { String(format: NSLocalizedString("%@ Wallet Address", comment: ""), $0.cryptoCurrency ?? "")}
            .bind(to: walletTextField.rx.title)
            .disposed(by: disposeBag)
        
        reactor.state.map { !$0.isSNNAvailable }
            .bind(to: ssnTextField.rx.isHidden )
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.areTermsAndPolicyAccepted }
            .bind(to: agreeCheckbox.rx.isChecked)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isEditable }.subscribe(onNext: { [unowned self] isEditable in
            self.documentsView.isUserInteractionEnabled = isEditable
            self.cardNumberTextField.isUserInteractionEnabled = isEditable
            self.expiryDateTextField.isUserInteractionEnabled = isEditable
            self.cvvTextField.isUserInteractionEnabled = isEditable
            self.walletTextField.isUserInteractionEnabled = isEditable
            self.ssnTextField.isUserInteractionEnabled = isEditable
            self.agreeCheckbox.isUserInteractionEnabled = isEditable
        
            self.nextButtonView.isHidden = !isEditable
        }).disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.alert }.subscribe(onNext: { [unowned self] alert in
            self.delegate?.showServiceDownError()
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.validationErrors }.subscribe(onNext: { [unowned self] validationErrors in
            self.cardNumberTextField.error = nil
            self.cvvTextField.error = nil
            self.walletTextField.error = nil
            self.expiryDateTextField.error = nil
            self.ssnTextField.error = nil
            self.agreeCheckbox.errorString = nil
            for (index, validationError) in validationErrors.enumerated() {
                switch validationError.key {
                case .cardNumber:
                    self.cardNumberTextField.error = validationError.value
                    if index == 0 {
                        self.delegate?.scrollToErrorField(field: self.cardNumberTextField)
                    }
                case .expiryDate:
                    self.expiryDateTextField.error = validationError.value
                    if index == 0 {
                        self.delegate?.scrollToErrorField(field: self.expiryDateTextField)
                    }
                case .cvv:
                    self.cvvTextField.error = validationError.value
                    if index == 0 {
                        self.delegate?.scrollToErrorField(field: self.cvvTextField)
                    }
                case .walletAddress:
                    self.walletTextField.error = validationError.value
                    if index == 0 {
                        self.delegate?.scrollToErrorField(field: self.walletTextField)
                    }
                case .ssn:
                    self.ssnTextField.error = validationError.value
                    if index == 0 {
                        self.delegate?.scrollToErrorField(field: self.ssnTextField)
                    }
                case .termsAndPolicy:
                    self.agreeCheckbox.errorString = validationError.value
                    if index == 0 {
                        self.delegate?.scrollToErrorField(field: self.agreeCheckbox)
                    }
                }
            }
        }).disposed(by: disposeBag)
        
        reactor.state.filter { $0.isFinished }.subscribe(onNext: { [unowned self] _ in
            self.delegate?.submitionFinishedSubject.onNext(())
        }).disposed(by: disposeBag)
        
        cardNumberTextField.rx.text.skip(1).map { Reactor.Action.enterCardNumber($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        cvvTextField.rx.text.skip(1).map { Reactor.Action.enterCVV($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        ssnTextField.rx.text.map { Reactor.Action.enterSNN($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        walletTextField.rx.text.skip(1).map { Reactor.Action.enterWallet($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        agreeCheckbox.rx.isChecked.skip(1).map { Reactor.Action.setTermsAccepted($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedDateSubject.map { Reactor.Action.selectExpiryDate($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        scannedQRCode.map { Reactor.Action.enterWallet($0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        areAllImagesUploadedBehaviorSubject.map { Reactor.Action.setAllImagesUploaded($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        delegate?.nextTap.asObservable().takeUntil(reactor.state.filter { $0.isFinished || !$0.isEditable })
            .throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.submit }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        if let delegate = delegate {
            reactor.state.map { $0.isLoading }.distinctUntilChanged()
                .bind(to: delegate.loadingSubject)
                .disposed(by: disposeBag)
        }
        
        if let uploadPhotoViewController = uploadPhotoViewController {
            delegate?.nextTap.asObservable().takeUntil(reactor.state.filter { $0.isFinished || !$0.isEditable })
                .throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
                .bind(to: uploadPhotoViewController.checkAllImagesUploadedSubject)
                .disposed(by: disposeBag)
        }
    }

    // MARK: - Implementation
    
    @IBOutlet private weak var documentsView: UIView!
    @IBOutlet private weak var cardNumberTextField: CDTextField!
    @IBOutlet private weak var expiryDateTextField: CDTextField!
    @IBOutlet private weak var cvvTextField: CDTextField!
    @IBOutlet private weak var walletTextField: CDTextField!
    @IBOutlet private weak var ssnTextField: CDTextField!
    @IBOutlet private weak var agreeCheckbox: CDCheckbox!
    @IBOutlet private weak var nextButtonView: UIView!
    @IBOutlet private weak var chooseDocumentTypeLabel: UILabel!
    
    private let selectedDateSubject = PublishSubject<Date>()
    private let scannedQRCode = PublishSubject<String>()
    private let areAllImagesUploadedBehaviorSubject = BehaviorSubject<Bool>(value: false)
    
    private var expiryDateFormatter: DateFormatter {
        let result = DateFormatter()
        result.dateFormat = "MM/yy"
        return result
    }
    
    private func addSpaceAfterSymbols(_ text: String?) -> String {
        guard var originalString = text else {
            return ""
        }
        
        if originalString.count == 0 {
            return originalString
        }

        var resultString = originalString
        originalString = originalString.replacingOccurrences(of: " ", with: "")
        
        if originalString.count == Constant.Card.CardNumberLenght {
            return resultString
        }
        
        if originalString.count % 4 == 0 {
            resultString = resultString + " "
        }

        return resultString
    }
    
    private func showCVVInfoView() {
        if let cvvInfoViewController = UIStoryboard(name: "CDBaseSheet", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CDBaseSheetController,
            let sheetContainerController = UIStoryboard(name: "CEXBottomSheetContainer", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CEXBottomSheetContainerController {
            
            cvvInfoViewController.setUp(title: NSLocalizedString("CVV", comment: ""), description: NSLocalizedString("A 3-digit number in reverse italics on the back of your credit card", comment: ""), hideCancelButton: true, actionTitle: NSLocalizedString("OK", comment: ""), actionButtonStyle: nil, action: nil)
            sheetContainerController.setup(contentViewController: cvvInfoViewController)
            present(sheetContainerController, animated: true, completion: nil)
        }
    }
    
    private func showQRScannerView() {
        let qrScannerViewController = QRScannerViewController.cd_instantiateFromStoryboard()
        qrScannerViewController.delegate = self
        present(qrScannerViewController, animated: true, completion: nil)
    }
}

extension FillPaymentInfoViewController: CDTextFieldDelegate {
    
    func dateTextFieldSelectedDate(_ date: Date) {
        selectedDateSubject.onNext(date)
    }

    func textField(_ textField: CDTextField, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text.count < 1) {
            return true;
        }

        if let textString = textField.text {
            if textField == cardNumberTextField {
                cardNumberTextField.text = addSpaceAfterSymbols(textString)
                return textString.count < Constant.Card.CardNumberLenght + 3
            } else if textField == cvvTextField {
                return textString.count < Constant.Card.CvvNumberLenght
            } else if textField == ssnTextField {
                let allowedCharacterSet = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "-"))
                return CharacterSet(charactersIn: text).isSubset(of: allowedCharacterSet) && (textString.count - range.length + text.count) <= Constant.SSN.length
            }
        }

        return true;
    }
    
    func textFieldDidChange(_ textField: CDTextField) {
        if textField == ssnTextField {
            var validatedSSN = textField.text?.replacingOccurrences(of: "-", with: "") ?? ""
            for dashIndex in Constant.SSN.dashIndexes {
                if dashIndex < validatedSSN.count {
                    validatedSSN.insert("-", at: validatedSSN.index(validatedSSN.startIndex, offsetBy: dashIndex))
                }
            }
            
            textField.text = validatedSSN
        }
    }
    
    func textFieldButtonTapped(_ textField: CDTextField) {
        if textField == cvvTextField {
            showCVVInfoView()
        }
        
        if textField == walletTextField {
            showQRScannerView()
        }
    }
}

extension FillPaymentInfoViewController: QRScannerViewControllerDelegate {
    
    func scanningSuccessWithCode(qrCode: String) {
        scannedQRCode.onNext(qrCode)
    }
}

extension FillPaymentInfoViewController: UploadPhotoViewControllerDelegate {
    func scrollToDocumentTypeNotSelectedError() {
        self.delegate?.scrollToErrorField(field: self.chooseDocumentTypeLabel)
    }
    
    func scrollToDocumentErrorView(errorView: UIView) {
        self.delegate?.scrollToErrorField(field: errorView)
    }
    
    var areAllImagesUploadedSubject: BehaviorSubject<Bool>? {
        return areAllImagesUploadedBehaviorSubject
    }
    
    var loadingSubject: BehaviorSubject<Bool>? {
        return delegate?.loadingSubject
    }
}

extension FillPaymentInfoViewController: CDCheckboxDelegate {
    func didTapRule(didTapRule rule: String) {
        delegate?.didTapRule(didTapRule: rule)
    }
}
