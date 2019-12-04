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
//  Created by Ihor Vovk on 7/3/19.

import UIKit

/*@IBDesignable*/ class CDLoadingView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    // MARK: - Implementation
    
    @IBOutlet weak var progressView: CDProgressView!
    
    private func setUp() {
        cd_loadContentFromNib()
    }
    
    override var isHidden: Bool {
        didSet {
            if progressView != nil {
                if isHidden {
                    progressView.stopAnimation()
                } else {
                    progressView.startAnimation()
                }
            }
        }
    }
}
