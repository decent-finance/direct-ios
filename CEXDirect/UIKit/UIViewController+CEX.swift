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
//  Created by Ihor Vovk on 8/6/18 1:30 PM.

import UIKit

@objc extension UIViewController {
    
    @objc func swap(fromViewController: UIViewController?, toViewController: UIViewController, containerView: UIView) {
        toViewController.view.frame = containerView.bounds
        
        fromViewController?.willMove(toParent: nil)
        self.addChild(toViewController)
        
        let completion: () -> Void = {
            NSLayoutConstraint.activate([
                toViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                toViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                toViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                toViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            toViewController.didMove(toParent: self)
        }
        
        if let fromViewController = fromViewController, fromViewController.parent != nil {
            self.transition(from: fromViewController, to: toViewController, duration: 0.1, options: UIView.AnimationOptions.transitionCrossDissolve, animations: nil) { (Bool) -> Void in
                fromViewController.removeFromParent()
                completion()
            }
        } else {
            containerView.addSubview(toViewController.view)
            completion()
        }
    }
    
    @objc func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
}
