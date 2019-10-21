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
//  Created by Ihor Vovk on 4/17/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import WebKit

protocol ConfirmPaymentViewControllerDelegate: class {
    
    var loadingSubject: BehaviorSubject<Bool> { get }
}

class ConfirmPaymentViewController: UIViewController, StoryboardView {
    
    var delegate: ConfirmPaymentViewControllerDelegate?
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
    }
    
    func bind(reactor: ConfirmPaymentViewReactor) {
        reactor.state.map { $0.html }.subscribe(onNext: { [unowned self] html in
            if let html = html {
                self.webView.loadHTMLString(html, baseURL: nil)
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var webView: WKWebView!
}

extension ConfirmPaymentViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.loadingSubject.onNext(true)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.loadingSubject.onNext(false)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.loadingSubject.onNext(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.loadingSubject.onNext(false)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var credential: URLCredential? = nil
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust: trust)
        }
        
        completionHandler(.useCredential, credential)
    }
}
