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
//  Created by Ihor Vovk on 5/16/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol EditEmailViewControllerDelegate: class {
    
    var loadingSubject: BehaviorSubject<Bool> { get }
}


class EditEmailViewController: UIViewController, StoryboardView {
    
    weak var delegate: EditEmailViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    
    func bind(reactor: EditEmailViewReactor) {
        reactor.state.map { $0.email }
            .bind(to: emailTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.emailError }.subscribe(onNext: { [unowned self] error in
            self.emailTextField.error = error
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.alert }.filter { $0 != nil }.subscribe(onNext: { [unowned self] alert in
            self.cd_presentInfoAlert(message: alert)
        }).disposed(by: disposeBag)
        
        reactor.state.filter { $0.isFinished }.subscribe(onNext: { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        emailTextField.rx.text.map { Reactor.Action.editEmail($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        saveButton.rx.tap.throttle(.milliseconds(200), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.save }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        if let loadingSubject = delegate?.loadingSubject {
            reactor.state.map { $0.isLoading }.distinctUntilChanged()
                .bind(to: loadingSubject)
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var emailTextField: CDTextField!
    @IBOutlet private weak var saveButton: CDButton!
    @IBOutlet private weak var cancelButton: CDButton!
}
