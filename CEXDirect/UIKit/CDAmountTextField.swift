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
//  Created by Ihor Vovk on 4/5/19.

import UIKit
import RxSwift
import RxCocoa

@objc protocol CDAmountTextFieldDelegate: class {
    @objc optional func changeCurrency(_ textField: CDAmountTextField)
    @objc optional func textField(_ textField: CDAmountTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
}

/*@IBDesignable*/ class CDAmountTextField: UIControl {
    
    @IBInspectable var keyboardType: Int {
        get {
            return textField.keyboardType.rawValue
        }
        
        set(newType) {
            textField.keyboardType = UIKeyboardType(rawValue: newType) ?? .default
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
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    override var canBecomeFirstResponder: Bool {
        return textField.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    var text: String? {
        get {
            return textField.text
        }
        
        set(newText) {
            textField.text = newText
        }
    }
    
    var error: String? {
        didSet {
            update(theme: .dark)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet fileprivate weak var textField: UITextField!
    @IBOutlet weak var button: UIButton!
    @IBOutlet private weak var errorLabel: UILabel!
    
    weak var delegate: CDAmountTextFieldDelegate?
    
    private func setUp() {
        cd_loadContentFromNib()
        update(theme: .dark)
    }
    
    private func update(theme: Theme) {
        textField.textColor = (theme == .dark) ? .cd_white : .cd_gray30
        
        if isFirstResponder {
            containerView.borderColor = (theme == .dark) ? .cd_white : .cd_gray30
        } else if error != nil {
            containerView.borderColor = .cd_redNormal
        } else {
            containerView.borderColor = (theme == .dark) ? .cd_gray40 : .clear
        }
        
        errorLabel?.text = error
        errorLabel?.isHidden = error == nil || error?.count == 0
    }
    
    @IBAction private func changeCurrency(_ sender: Any) {
        delegate?.changeCurrency?(self)
    }
}

extension CDAmountTextField: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        containerView.borderColor = .white
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        containerView.borderColor = .gray
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        if let delegate = delegate, delegate.textField?(self, shouldChangeCharactersIn: range, replacementString: string) == false {
            return false
        }
        
        return string.rangeOfCharacter(from: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".,")).inverted) == nil
    }
}

extension Reactive where Base : CDAmountTextField {
    
    var text: RxCocoa.ControlProperty<String?> {
        return base.textField.rx.text
    }
    
    func buttonTitle(for controlState: UIControl.State = .normal) -> RxCocoa.Binder<String?> {
        return base.button.rx.title(for: controlState)
    }
}
