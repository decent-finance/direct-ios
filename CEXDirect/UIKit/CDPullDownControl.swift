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
//  Created by Ihor Vovk on 5/14/19.

import UIKit

/*@IBDesignable*/ class CDPullDownControl: UIControl {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    func setUp(title: String, contentView: UIView) {
        pickerButton.title = title
        containerView.cd_setContent(view: contentView)
    }
    
    // MARK: - Implementation
    
    private func setUp() {
        cd_loadContentFromNib()
        pickerButton.delegate = self
        pullDownView.isHidden = true
    }
    
    @IBOutlet private weak var pickerButton: CDPickerButton!
    @IBOutlet private weak var pullDownView: UIView!
    @IBOutlet private weak var containerView: UIView!
}

extension CDPullDownControl: CDPickerButtonDelegate {
    
    func pickerButtonDidTap(_ button: CDPickerButton) {
        pullDownView.isHidden = !pullDownView.isHidden
    }
}
