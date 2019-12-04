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
//  Created by Ihor Vovk on 11/5/19.

import UIKit

protocol BaseErrorViewControllerDelegate: class {
    func errorViewControllerDidTapButton(_ controller: BaseErrorViewController)
}

class BaseErrorViewController: UIViewController {
    
    weak var delegate: BaseErrorViewControllerDelegate?
    
    // MARK: - Implementation
    
    @IBAction private func tryAgainButtonHandler(_ sender: Any) {
        delegate?.errorViewControllerDidTapButton(self)
    }
}
