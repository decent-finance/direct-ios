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
//  Created by Alex Kovalenko on 6/7/19.

import UIKit

protocol ErrorInfoViewControllerDelegate: class {
    func errorInformationViewControllerDidTapButton(_ controller: ErrorInfoViewController)
}

class ErrorInfoViewController: UIViewController {
    
    @IBOutlet private weak var reasonErrorLabel: UILabel!
    
    weak var delegate: ErrorInfoViewControllerDelegate?
    var reasonErrorText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reasonErrorLabel.text = reasonErrorText
    }
    
    @IBAction func tryAgainButtonHandler(_ sender: Any) {
        delegate?.errorInformationViewControllerDidTapButton(self)
    }
}
