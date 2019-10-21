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
//  Created by Sergii Iastremskyi on 4/16/19.

import UIKit

extension UIViewController {
    
    class func cd_instantiateFromStoryboard() -> Self {
        return cd_instantiateFromStoryboardHelper(name: "\(self)", identifier: nil)
    }
    
    class func cd_instantiateFromStoryboard(name: String) -> Self {
        return cd_instantiateFromStoryboardHelper(name: name, identifier: nil)
    }
    
    class func cd_instantiateFromStoryboard(name: String, identifier: String) -> Self {
        return cd_instantiateFromStoryboardHelper(name: name, identifier: identifier)
    }
    
    func cd_addChildViewController(_ child: UIViewController, containerView: UIView? = nil) {
        guard let containerView = containerView ?? view else { return }
        
        addChild(child)

        child.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(child.view)
        
        child.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        child.view.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        child.view.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        
        child.didMove(toParent: self)
    }
    
    func cd_removeChildViewController(_ child: UIViewController, perform: (() -> ())? = nil) {
        
        child.willMove(toParent: nil)
        child.removeFromParent()
        if let perform = perform {
            perform()
        } else {
            child.view.removeFromSuperview()
        }
    }
    
    func cd_presentInfoAlert(title: String? = nil, message: String?, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            completion?()
        })
        
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Implementation
    
    private class func cd_instantiateFromStoryboardHelper<T>(name: String, identifier: String?) -> T {
        let controller: UIViewController?
        if let identifier = identifier {
            controller = UIStoryboard(name: name, bundle: Bundle(for: self)).instantiateViewController(withIdentifier: identifier)
        } else {
            controller = UIStoryboard(name: name, bundle: Bundle(for: self)).instantiateInitialViewController()
        }
        
        return controller as! T
    }
}
