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
import SVProgressHUD

protocol FillBaseInfoViewControllerDelegate: class {
    
    var nextTap: RxCocoa.ControlEvent<Void> { get }
    var submitionFinishedSubject: PublishSubject<Void> { get }
    var locationNotSupportedSubject: BehaviorSubject<Bool> { get }
    var loadingSubject: BehaviorSubject<Bool> { get }
    
    func showServiceDownError()
}

class FillBaseInfoViewController: UIViewController, StoryboardView {
    
    weak var delegate: FillBaseInfoViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countryPickerButton.delegate = self
        statePickerButton.delegate = self
    }
    
    func bind(reactor: FillBaseInfoViewReactor) {
        reactor.state.map { $0.email }
            .bind(to: emailTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.countryName }
            .bind(to: countryPickerButton.rx.selection)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.stateName }
            .bind(to: statePickerButton.rx.selection)
            .disposed(by: disposeBag)
        
        reactor.state.map { !$0.isStateAvailable }
            .bind(to: statePickerButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isEditable }.subscribe(onNext: { [unowned self] isEditable in
            self.emailTextField.isUserInteractionEnabled = isEditable
            self.countryPickerButton.isUserInteractionEnabled = isEditable
            self.statePickerButton.isUserInteractionEnabled = isEditable
            
            self.nextButtonView.isHidden = !isEditable
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.validationErrors }.subscribe(onNext: { [unowned self] validationErrors in
            self.emailTextField.error = nil
            self.countryPickerButton.error = nil
            self.statePickerButton.error = nil

            for validationError in validationErrors {
                switch validationError.key {
                case .email:
                    self.emailTextField.error = validationError.value
                case .country:
                     self.countryPickerButton.error = validationError.value
                case .state:
                    self.statePickerButton.error = validationError.value
                }
            }
        }).disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.alert }.subscribe(onNext: { [unowned self] alert in
            self.delegate?.showServiceDownError()
        }).disposed(by: disposeBag)

        reactor.state.filter { $0.isFinished }.subscribe(onNext: { [unowned self] _ in
            self.delegate?.submitionFinishedSubject.onNext(())
        }).disposed(by: disposeBag)
        
        emailTextField.rx.text.skip(1).map { Reactor.Action.enterEmail($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedCountryCodeSubject.map { Reactor.Action.selectCountry($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedCountryNameSubject.map { Reactor.Action.selectCountryName($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedCountryStateSubject.map { Reactor.Action.selectState($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedCountryStateCodeSubject.map { Reactor.Action.selectStateCode($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        delegate?.nextTap.takeUntil(reactor.state.filter { $0.isFinished || !$0.isEditable })
            .throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.submit }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        if let delegate = delegate {
            reactor.state.map { $0.locationNotSupported }
                .bind(to: delegate.locationNotSupportedSubject)
                .disposed(by: disposeBag)
            
            reactor.state.map { $0.isLoading }.distinctUntilChanged()
                .bind(to: delegate.loadingSubject)
                .disposed(by: disposeBag)
        }
    }

    // MARK: - Implementation
    
    @IBOutlet private weak var emailTextField: CDTextField!
    @IBOutlet private weak var countryPickerButton: CDPickerButton!
    @IBOutlet private weak var statePickerButton: CDPickerButton!
    @IBOutlet private weak var nextButtonView: UIView!
    
    let selectedCountryCodeSubject = PublishSubject<String>()
    let selectedCountryNameSubject = PublishSubject<String>()
    let selectedCountryStateSubject = PublishSubject<String>()
    let selectedCountryStateCodeSubject = PublishSubject<String>()
}

extension FillBaseInfoViewController: CDPickerButtonDelegate {
    
    func pickerButtonDidTap(_ button: CDPickerButton) {
        if let countryPickerViewController = UIStoryboard(name: "CDPickerViewController", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CDPickerViewController,
            let sheetContainerController = UIStoryboard(name: "CEXBottomSheetContainer", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CEXBottomSheetContainerController {
            countryPickerViewController.delegate = self
            countryPickerViewController.pickerButton = button
            if button == countryPickerButton {
                countryPickerViewController.selectedCode = countryPickerButton.selection
                countryPickerViewController.countries = reactor?.currentState.countries
            } else {
                countryPickerViewController.selectedCode = statePickerButton.selection
                countryPickerViewController.countryStates = reactor?.currentState.countryStates
            }
            sheetContainerController.setup(contentViewController: countryPickerViewController)
            present(sheetContainerController, animated: true, completion: nil)
        }
    }
}

extension FillBaseInfoViewController: CDPickerDelegate {
    func selectedPickerValue(button: CDPickerButton, dict: Dictionary<String, String>) {
        if let countryCode = dict[CDPickerEnum.code.rawValue] {
            button == countryPickerButton ? selectedCountryCodeSubject.onNext(countryCode) : selectedCountryStateCodeSubject.onNext(countryCode)
        }
        
        if let countryName = dict[CDPickerEnum.name.rawValue] {
            button == countryPickerButton ? selectedCountryNameSubject.onNext(countryName) : selectedCountryStateSubject.onNext(countryName)
        }
    }
}
