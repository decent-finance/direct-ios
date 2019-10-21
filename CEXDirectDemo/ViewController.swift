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
//  Created by Ihor Vovk on 3/25/19.

import UIKit
import CEXDirect

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openCEXDirect(_ sender: Any) {
        guard let placementSettingsPath = Bundle.main.path(forResource: "Placement", ofType: "plist"), let placementSettings = NSDictionary(contentsOfFile: placementSettingsPath), let placementID = placementSettings["PlacementID"] as? String, let secret = placementSettings["PlacementSecret"] as? String else {
            cd_presentInfoAlert(message: "Missing placement ID or secret")
            return
        }
        
        let cexDirect = CEXDirect(placementID: placementID, secret: secret, fiatAmount: fiatAmountTextField.text, email: emailTextField.text, countryCode: countryTextField.text)
        guard let rootViewController = cexDirect.rootViewController else {
            return
        }
        
        present(rootViewController, animated: true, completion: nil)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var fiatAmountTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var countryTextField: UITextField!
}
