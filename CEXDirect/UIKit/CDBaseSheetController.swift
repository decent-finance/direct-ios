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
//  Created by Ihor Vovk on 7/15/19.

import UIKit

class CDBaseSheetController: UIViewController {
    
    func setUp(title: String? = nil, description: String? = nil, hideCancelButton: Bool = false, actionTitle: String? = nil, actionButtonStyle: String? = nil, action: (() -> Void)?) {
        sheetTitle = title
        sheetDescription = description
        self.hideCancelButton = hideCancelButton
        self.actionTitle = actionTitle
        self.actionButtonStyle = actionButtonStyle
        self.action = action
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .cd_gray20
        
        titleLabel.textColor = .cd_white
        descriptionLabel?.textColor = .cd_white
        
        titleLabel.text = sheetTitle
        titleLabel.isHidden = (sheetTitle == nil)
        
        descriptionLabel?.text = sheetDescription
        descriptionLabel?.isHidden = (sheetDescription == nil)
        
        cancelButton.isHidden = hideCancelButton
        
        actionButton.title = actionTitle
        actionButton.isHidden = (actionTitle == nil)
    
        if let actionButtonStyle = actionButtonStyle {
            actionButton.style = actionButtonStyle
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel?
    @IBOutlet private weak var actionButton: CDButton!
    @IBOutlet private weak var cancelButton: CDButton!
    
    private var sheetTitle: String?
    private var sheetDescription: String?
    private var hideCancelButton = false
    private var actionTitle: String?
    private var actionButtonStyle: String?
    private var action: (() -> Void)?
    
    @IBAction private func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func performAction(_ sender: Any) {
        dismiss(animated: true, completion: action)
    }
}
