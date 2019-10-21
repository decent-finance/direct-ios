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
//  Created by Ihor Vovk on 7/1/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import MarkdownView
import WebKit

class RuleViewController: UIViewController, StoryboardView {
    
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for subview in markdownView.subviews {
            if let webView = subview as? WKWebView {
                webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: okButton.frame.height, right: 0)
                break
            }
        }
    }
    
    func bind(reactor: RuleViewReactor) {
        reactor.state.map { $0.rule }.subscribe(onNext: { [unowned self] rule in
            self.markdownView.load(markdown: rule)
        }).disposed(by: disposeBag)
        
        okButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Implementation
    
    @IBOutlet weak var markdownView: MarkdownView!
    @IBOutlet weak var okButton: CDButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
