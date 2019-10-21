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
//  Created by Ihor Vovk on 7/16/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

class LocationUnsupportedViewController: UIViewController, StoryboardView {
    
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func bind(reactor: LocationUnsupportedViewReactor) {
        reactor.state.map { $0.email }
            .bind(to: emailTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.emailError }.subscribe(onNext: { [unowned self] error in
            self.emailTextField.error = error
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.isAgreedToReceiveNotification }
            .bind(to: agreeCheckbox.rx.isChecked)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.agreeToReceiveNotificationError }.subscribe(onNext: { [unowned self] error in
            self.agreeCheckbox.error = error
        }).disposed(by: disposeBag)
        
        emailTextField.rx.text.skip(1).map { Reactor.Action.editEmail($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        agreeCheckbox.rx.isChecked.skip(1).map { Reactor.Action.agreeToReceiveNotification($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        informMeButton.rx.tap.map { Reactor.Action.informMe }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }

    // MARK: - Implementation

    @IBOutlet private weak var emailTextField: CDTextField!
    @IBOutlet private weak var agreeCheckbox: CDCheckbox!
    @IBOutlet private weak var informMeButton: CDButton!
}
