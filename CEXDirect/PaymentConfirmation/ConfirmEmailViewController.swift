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
//  Created by Ihor Vovk on 4/17/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol ConfirmEmailViewControllerDelegate: class {
    
    var nextTap: RxCocoa.ControlEvent<Void> { get }
    var submitionFinishedSubject: PublishSubject<Void> { get }
    var loadingSubject: BehaviorSubject<Bool> { get }
    
    func сonfirmEmailViewControllerDidTapEditEmail(_ controller: ConfirmEmailViewController)
}

class ConfirmEmailViewController: UIViewController, StoryboardView {
    
    weak var delegate: ConfirmEmailViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    
    var submitButtonBottomOffset: CGFloat {
        view.layoutIfNeeded()
        return view.bounds.height - submitButton.frame.maxY
    }
    
    let isRunning = BehaviorRelay(value: true)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.resendTimeLabelText(Constant.ConfirmEmail.resendCodeTime)
        isRunning.accept(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isRunning.accept(false)
    }
    
    func bind(reactor: ConfirmEmailViewReactor) {
        
        isRunning.asObservable()
            .flatMapLatest { isRunning in
                isRunning ? Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance) : .empty()
            }
            .flatMap { index in Observable.just(index + 1) }
            .subscribe(onNext: { [unowned self] seconds in
                let time = Constant.ConfirmEmail.resendCodeTime - seconds
       
                if time <= 0 {
                    self.resendTimeButton.isHidden = true
                    self.resendCodeButton.isHidden = false
                    self.isRunning.accept(false)
                }
                
                self.resendTimeLabelText(time)
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.email }
            .bind(to: emailLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.code }
            .bind(to: codeTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.codeError }.subscribe(onNext: { [unowned self] error in
            self.codeTextField.error = error
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.alert }.filter { $0 != nil }.subscribe(onNext: { [unowned self] alert in
            self.cd_presentInfoAlert(message: alert)
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.isCodeResend }.filter { $0 != nil }.subscribe(onNext: { [unowned self] isCodeResend in
            if isCodeResend ?? false {
                self.resendTimeButton.isHidden = false
                self.resendCodeButton.isHidden = true
                self.resendTimeLabelText(Constant.ConfirmEmail.resendCodeTime)
                self.isRunning.accept(true)
                self.cd_presentInfoAlert(message: NSLocalizedString("We have sent you a confirmation code. Please check your email.", comment: ""))
            } else {
                self.cd_presentInfoAlert(message: NSLocalizedString("Failed to send confirmation code", comment: ""))
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.isFinished }.distinctUntilChanged().filter { $0 }.subscribe(onNext: { [unowned self] isFinished in
            self.delegate?.submitionFinishedSubject.onNext(())
        }).disposed(by: disposeBag)
        
        codeTextField.rx.text.skip(1).map { Reactor.Action.enterCode($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        Observable.merge(submitButton.rx.tap.asObservable(), delegate?.nextTap.asObservable() ?? Observable.empty())
            .takeUntil(reactor.state.filter { $0.isFinished })
            .throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.submit }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        resendCodeButton.rx.tap.map { Reactor.Action.resendCode }
            .throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        if let loadingSubject = delegate?.loadingSubject {
            reactor.state.map { $0.isLoading }.distinctUntilChanged()
                .bind(to: loadingSubject)
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var codeTextField: CDTextField!
    @IBOutlet private weak var submitButton: CDButton!
    @IBOutlet private weak var editEmailButton: CDButton!
    @IBOutlet private weak var resendCodeButton: CDButton!
    @IBOutlet private weak var resendTimeButton: CDButton!
    
    @IBAction func editEmail(_ sender: Any) {
        delegate?.сonfirmEmailViewControllerDidTapEditEmail(self)
    }
    
    private func resendTimeLabelText(_ time: Int) {
        let minute = (time / 60) % 60
        let second = time % 60
        
        self.resendTimeButton.title = String(format: "%02ld:%02ld", minute, second)
    }
}
