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
import RxSwift
import RxCocoa

class FillInfoContainerViewController: UIViewController {
    
    typealias SectionViewControllerInfo = (title: String, controller: UIViewController)
    
    private(set) var mainViewController: UIViewController!
    
    func setUp(mainViewController: UIViewController, sectionViewControllers: [SectionViewControllerInfo]) {
        self.mainViewController = mainViewController
        self.sectionViewControllers = sectionViewControllers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cd_addChildViewController(mainViewController, containerView: mainContainerView)
        
        for controllerInfo in sectionViewControllers {
            addChild(controllerInfo.controller)
            
            let pullDownControl = CDPullDownControl(frame: CGRect.zero)
            pullDownControl.setUp(title: controllerInfo.title, contentView: controllerInfo.controller.view)
            pullDownControl.translatesAutoresizingMaskIntoConstraints = false
            pullDownControl.accessibilityIdentifier = controllerInfo.title
            
            expandableSectionStackView.addArrangedSubview(pullDownControl)
            
            controllerInfo.controller.didMove(toParent: self)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var expandableSectionStackView: UIStackView!
    @IBOutlet private weak var mainContainerView: UIView!
    
    private var sectionViewControllers: [SectionViewControllerInfo]!
}
