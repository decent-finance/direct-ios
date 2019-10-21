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
//  Created by Ihor Vovk on 7/18/18 10:15 AM.

import UIKit
import RxCocoa
import RxSwift
import Nantes

protocol CDCheckboxDelegate: class {
    func didTapRule(didTapRule rule: String)
}

/*@IBDesignable*/ class CDCheckbox: UIControl {
    
    private var disposeBag = DisposeBag()
    
    @IBInspectable var message: String? {
        get {
            return messageLabel.text
        }
        
        set(newMessage) {
            messageLabel.text = newMessage
            messageLabel.isHidden = (newMessage?.count == 0)
        }
    }
    
    var error: Bool = false {
        didSet {
            update()
        }
    }
    
    var errorString: String? {
        didSet {
            update()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    // MARK: - Implementation
    
    @IBOutlet fileprivate weak var checkButton: UIButton!
    @IBOutlet fileprivate weak var messageLabel: NantesLabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var errorLabel: UILabel!
    
    weak var delegate: CDCheckboxDelegate?

    @IBAction func didTouch(_ sender: Any) {
        checkButton.isSelected = !checkButton.isSelected
        error = false
        errorString = nil

        sendActions(for: .valueChanged)
        sendActions(for: .touchUpInside)
    }
    
    private func setUp() {
        cd_loadContentFromNib()
        messageLabel.isHidden = true
        messageLabel.delegate = self
        
        messageLabel.linkAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
    
    private func update() {
        let bundle = Bundle(for: type(of: self))
        if error || errorString != nil {
            checkButton.setImage(UIImage(named: "ic_check_error", in: bundle, compatibleWith: nil), for: .normal)
            containerView.layer.borderColor = UIColor.cd_redNormal.cgColor
        } else {
            let imageName = isSelected ? "ic_check_full" : "ic_check_empty"
            checkButton.setImage(UIImage(named: imageName, in: bundle, compatibleWith: nil), for: .normal)
            containerView.layer.borderColor = UIColor.cd_gray40.cgColor
        }
        
        errorLabel?.text = errorString
        errorLabel?.isHidden = errorString == nil || errorString?.count == 0
    }
}

extension Reactive where Base : CDCheckbox {
    
    var isChecked: RxCocoa.ControlProperty<Bool> {
        return controlProperty(editingEvents: .valueChanged, getter: { checkbox in
            checkbox.checkButton.isSelected
        }, setter: { checkbox, isSelected in
            checkbox.checkButton.isSelected = isSelected
        })
    }
    
    var message: RxCocoa.Binder<String?> {
        return base.messageLabel.rx.text
    }
}

extension CDCheckbox: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        if let string = String(data: link.dataRepresentation, encoding: .utf8) {
            delegate?.didTapRule(didTapRule: string)
        }
    }
}

extension CDCheckbox {
    func configLabelWithRules(_ rules: [Rule]) -> String {
        return String(rules.reduce(Constant.CDCheckbox.startRuleText) { ( result: String, rule: Rule) -> String in
            return result + "\(rule.name ?? ""), ".capitalized
            }.dropLast(2))
    }
    
    func addLinkWithRules(_ rules: [Rule]) {
        var i = Constant.CDCheckbox.startRuleText.count
        for rule in rules {
            if let ruleValue = rule.value, let ruleName = rule.name?.capitalized, let ruleData = ruleValue.data(using: .utf8), let url = URL(dataRepresentation: ruleData, relativeTo: nil) {
                let range = NSRange(location: i, length: ruleName.count)
                i += ruleName.count + ", ".count
                self.messageLabel.addLink(to: url, withRange: range)
            }
        }
    }
}
