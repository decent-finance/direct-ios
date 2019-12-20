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
//  Created by Ihor Vovk on 7/20/18 3:07 PM.

import UIKit

@objc protocol CEXBottomSheetContainerControllerDelegate: class {
    
    @objc func bottomSheetContainerControllerWillDismiss(_ bottomSheetController: CEXBottomSheetContainerController)
}

@objc class CEXBottomSheetContainerController: UIViewController {
    
    @objc weak var delegate: CEXBottomSheetContainerControllerDelegate?
    
    @objc func setup(contentViewController: UIViewController) {
        self.contentViewController = contentViewController;
    }
    
    var backgroundColor: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        swap(fromViewController: nil, toViewController: contentViewController, containerView: sheetView)
        if let backgroundColor = backgroundColor {
            sheetView.backgroundColor = backgroundColor
        }
        sheetView.layoutIfNeeded()
        
        transitioningDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var sheetView: UIView!
    @IBOutlet private weak var keyboardConstraint: NSLayoutConstraint!
    
    private var contentViewController: UIViewController!
    private let animationDuration = 0.2
    
    @IBAction private func cancel(_ sender: Any) {
        delegate?.bottomSheetContainerControllerWillDismiss(self)
        dismiss(animated: true, completion: nil)
    }
    
    private func animatePresentingTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(view)
        
        view.backgroundColor = view.backgroundColor?.withAlphaComponent(0)
        sheetView.frame = sheetView.frame.offsetBy(dx: 0, dy: sheetView.frame.height)
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(0.7)
            self.sheetView.frame = self.sheetView.frame.offsetBy(dx: 0, dy: -self.sheetView.frame.height)
        }) { didComplete in
            transitionContext.completeTransition(didComplete)
        }
    }
    
    private func animateDismissingTransition(using transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(0)
            self.sheetView.frame = self.sheetView.frame.offsetBy(dx: 0, dy: self.sheetView.frame.height)
        }) { didComplete in
            transitionContext.completeTransition(didComplete)
        }
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                return
        }
        
        keyboardConstraint.constant = keyboardFrameValue.cgRectValue.height
        UIView.animate(withDuration: duration.doubleValue, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return
        }
        
        keyboardConstraint.constant = 0
        UIView.animate(withDuration: duration.doubleValue, animations: {
            self.view.layoutIfNeeded()
        })
    }
}

extension CEXBottomSheetContainerController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension CEXBottomSheetContainerController: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let toViewController = transitionContext.viewController(forKey: .to), toViewController.isKind(of: type(of: self)) {
            animatePresentingTransition(using: transitionContext)
        } else {
            animateDismissingTransition(using: transitionContext)
        }
    }
}
