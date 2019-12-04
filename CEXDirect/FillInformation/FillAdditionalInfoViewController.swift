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
//  Created by Ihor Vovk on 5/10/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol FillAdditionalInfoViewControllerDelegate: class {
    
    var nextTap: RxCocoa.ControlEvent<Void> { get }
    var submitionFinishedSubject: PublishSubject<Void> { get }
    var loadingSubject: BehaviorSubject<Bool> { get }
    
    func scrollToErrorField(field: UIView)
}

class FillAdditionalInfoViewController: UIViewController, StoryboardView {
    
    weak var delegate: FillAdditionalInfoViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    
    func bind(reactor: FillAdditionalInfoViewReactor) {
        reactor.state.subscribe(onNext: { [unowned self] state in
            var errorControl: UIControl? = nil
            for (index, key) in Order.AdditionalInfoKey.allCases.enumerated() {
                let control = self.additionalInfoControls[index]
                control.isHidden = state.additionalInfo[key.rawValue] == nil
                control.isEnabled = state.additionalInfo[key.rawValue]?.isEditable == true
                
                if let textField = control as? CDTextField {
                    textField.text = state.additionalInfo[key.rawValue]?.value
                    textField.error = state.validationErrors[key.rawValue]
                } else if let pickerButton = control as? CDPickerButton {
                    pickerButton.selection = state.additionalInfo[key.rawValue]?.value
                }
                
                if state.validationErrors.count > 0 && state.validationErrors[key.rawValue] != nil && errorControl == nil {
                    errorControl = control
                }
            }
            
            // Workaround for backend issues
            self.residentialPostcodeTextField.title = NSLocalizedString(state.additionalInfo[Order.AdditionalInfoKey.userResidentialCountry.rawValue]?.value == "US" ? "ZIP Code" : "Postcode", comment: "")
            
            if let errorField = errorControl {
                self.delegate?.scrollToErrorField(field: errorField)
                errorControl = nil
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.alert }.filter { $0 != nil }.subscribe(onNext:{ [unowned self] alert in
            self.cd_presentInfoAlert(message: alert)
        }).disposed(by: disposeBag)
        
        reactor.state.filter { $0.isFinished }.subscribe(onNext: { [unowned self] _ in
            self.hideKeyboard()
            self.delegate?.submitionFinishedSubject.onNext(())
        }).disposed(by: disposeBag)
        
        for (index, key) in Order.AdditionalInfoKey.allCases.enumerated() {
            let control = additionalInfoControls[index]
            if let textField = control as? CDTextField {
                textField.rx.text.skip(1).map { Reactor.Action.edit(property: key, value: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: disposeBag)
            } else if let pickerButton = control as? CDPickerButton {
                pickerButton.rx.selection.skip(1).map { Reactor.Action.edit(property: key, value: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: disposeBag)
            }
        }
        
        Observable.merge(verifyButton.rx.tap.asObservable(), delegate?.nextTap.asObservable() ?? Observable.empty())
            .takeUntil(reactor.state.filter { $0.isFinished })
            .throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.verify }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        if let loadingSubject = delegate?.loadingSubject {
            reactor.state.map { $0.isLoading }.distinctUntilChanged()
                .bind(to: loadingSubject)
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private var additionalInfoControls: [UIControl]!
    
    @IBOutlet private weak var firstNameTextField: CDTextField!
    @IBOutlet private weak var lastNameTextField: CDTextField!
    @IBOutlet private weak var middleNameTextField: CDTextField!
    @IBOutlet private weak var dateOfBirthTextField: CDTextField!
    @IBOutlet private weak var residentialCountryTextField: CDTextField!
    @IBOutlet private weak var residentialCityTextField: CDTextField!
    @IBOutlet private weak var residentialStreetTextField: CDTextField!
    @IBOutlet private weak var residentialSuiteTextField: CDTextField!
    @IBOutlet private weak var residentialPostcodeTextField: CDTextField!
    @IBOutlet private weak var residentialPostcodeUKTextField: CDTextField!
    @IBOutlet private weak var ruPassportTextField: CDTextField!
    @IBOutlet private weak var ruPassportIssueDateTextField: CDTextField!
    @IBOutlet private weak var ruPassportIssuedByTextField: CDTextField!
    @IBOutlet private weak var ruPhoneTextField: CDTextField!
    @IBOutlet private weak var billingCountryTextField: CDTextField!
    @IBOutlet private weak var billingStateTextField: CDTextField!
    @IBOutlet private weak var billingCityTextField: CDTextField!
    @IBOutlet private weak var billingStreetTextField: CDTextField!
    @IBOutlet private weak var billingZipCodeTextField: CDTextField!
    @IBOutlet private weak var billingSSNTextField: CDTextField!
    
    @IBOutlet private weak var verifyButton: CDButton!
}
