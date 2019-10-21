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
//  Created by Ihor Vovk on 6/28/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol VerifyPlacementViewControllerDelegate: class {
    
    func verifyPlacementViewController(_ viewController: VerifyPlacementViewController, didVerifySupported isSupported: Bool)
    func verifyPlacementViewControllerDidTapExit(_ viewController: VerifyPlacementViewController)
}

class VerifyPlacementViewController: UIViewController, StoryboardView {
    
    weak var delegate: VerifyPlacementViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    
    func bind(reactor: VerifyPlacementViewReactor) {
        reactor.state.filter { $0.isPlacementSupported != nil }.subscribe(onNext: { [unowned self] state in
            guard let isPlacementSupported = state.isPlacementSupported else { return }
            
            if state.areRulesLoaded {
                self.delegate?.verifyPlacementViewController(self, didVerifySupported: isPlacementSupported)
            }
            
            if !isPlacementSupported {
                self.errorView.isHidden = false
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { !$0.isLoading }
            .bind(to: loadingView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var loadingView: CDLoadingView!
    
    @IBAction private func exit(_ sender: Any) {
        delegate?.verifyPlacementViewControllerDidTapExit(self)
    }
}
