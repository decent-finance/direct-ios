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
//  Created by Ihor Vovk on 3/29/19.

import UIKit
import RxSwift
import RxCocoa

@objc protocol CDTextFieldDelegate: class {
    @objc optional func textField(_ textField: CDTextField, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    @objc optional func dateTextFieldSelectedDate(_ date: Date)
    @objc optional func textFieldButtonTapped(_ textField: CDTextField)
    @objc optional func textFieldDidChange(_ textField: CDTextField)
}

/*@IBDesignable*/ class CDTextField: UIControl {

    @IBInspectable var icon: String? = nil {
        didSet {
            if let icon = icon {
                iconImageView.image = UIImage(named: icon, in: Bundle(for: type(of: self)), compatibleWith: nil)
            } else {
                iconImageView.image = nil
            }
            
            update(theme: .dark)
        }
    }
    
    @IBInspectable var shouldShowTitle: Bool = true {
        didSet {
            self.titleLabel.isHidden = !shouldShowTitle
        }
    }
    
    @IBInspectable var buttonIcon: String? = nil {
        didSet {
            if let icon = buttonIcon {
                let image = UIImage(named: icon, in: Bundle(for: type(of: self)), compatibleWith: nil)
                button.setImage(image, for: .normal)
            } else {
                button.setImage(nil, for: .normal)
            }
            
            update(theme: .dark)
        }
    }
    
    @IBInspectable var title: String? {
        get {
            return titleLabel.text
        }
        
        set(newPlaceholder) {
            titleLabel.text = newPlaceholder
        }
    }
    
    @IBInspectable var containerBackgroundColor: UIColor? {
        get {
            return containerView.backgroundColor
        }
        
        set(newBackgroundColor) {
            containerView.backgroundColor = newBackgroundColor
            errorLabel.backgroundColor = newBackgroundColor
        }
    }
    
    @IBInspectable var keyboardType: Int {
        get {
            return textView.keyboardType.rawValue
        }
        
        set(newType) {
            textView.keyboardType = UIKeyboardType(rawValue: newType) ?? .default
        }
    }
    
    @IBInspectable var isDatePickerTextField: Bool = false {
        didSet {
            if isDatePickerTextField {
                let datePicker = CDMonthYearPickerView()
                datePicker.onSelect = { [unowned self] selectedDate in
                    self.delegate?.dateTextFieldSelectedDate?(selectedDate)
                }
                
                let toolbar = UIToolbar();
                toolbar.sizeToFit()
                let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker))
                toolbar.setItems([doneButton], animated: false)
                
                textView.inputAccessoryView = toolbar
                textView.inputView = datePicker
            }
        }
    }
    
    @IBInspectable var isSecureTextEntry: Bool {
        get {
            return textView.isSecureTextEntry
        }
        
        set(newSecureTextEntry) {
            textView.isSecureTextEntry = newSecureTextEntry
        }
    }
    
    weak var delegate: CDTextFieldDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    override var canBecomeFirstResponder: Bool {
        return textView.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    var text: String? {
        get {
            return isSecureTextEntry ? originalText : textView.text
        }
        
        set(newText) {
            textView.text = isSecureTextEntry ? maskSecurityText(text: newText) : newText
            originalText = newText ?? ""
            update(theme: .dark)
        }
    }
    
    var error: String? {
        didSet {
            update(theme: .dark)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var button: UIButton!
    
    @IBAction func buttonHandler(_ sender: Any) {
        delegate?.textFieldButtonTapped?(self)
    }
    
    private var originalText: String = ""
    
    private func setUp() {
        cd_loadContentFromNib()
        update(theme: .dark)
        
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 0)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: textView, action: #selector(becomeFirstResponder))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    fileprivate func update(theme: Theme) {
        if isFirstResponder {
            containerView.borderColor = (theme == .dark) ? .cd_white : .cd_gray20
        } else if error != nil {
            containerView.borderColor = .cd_redNormal
        } else {
            containerView.borderColor = (theme == .dark) ? .cd_gray40 : .clear
        }
        
        iconImageView.isHidden = (iconImageView.image == nil)
        button.isHidden = (button.image(for: .normal) == nil)
        
        if let text = textView.text, text.count > 0 || isFirstResponder {
            titleLabel.textColor = (theme == .dark) ? .cd_gray70 : .cd_gray5
            titleLabel.font = self.titleLabel.font.withSize(12)
            
            textView.isHidden = false
        } else {
            titleLabel.textColor = (theme == .dark) ? .cd_white : .cd_gray20
            self.titleLabel.font = self.titleLabel.font.withSize(16)
            
            textView.isHidden = true
        }

        errorLabel?.text = error
        errorLabel?.isHidden = error == nil || error?.count == 0
    }
    
    @objc private func doneDatePicker() {
        textView.resignFirstResponder()
    }
    
    private func maskSecurityText(text: String?) -> String {
        guard let textString = text else {
            return ""
        }
        
        return String(textString.map { _ -> Character in
            return "●"
        })
    }
}

extension CDTextField: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.update(theme: .dark)
        }) { isCompleted in
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.update(theme: .dark)
        }) { isCompleted in
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        if let delegate = delegate, delegate.textField?(self, shouldChangeTextIn: range, replacementText: text) == false {
            return false
        }
        
        if isSecureTextEntry {
            self.originalText = (originalText as NSString).replacingCharacters(in: range, with: text)
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        sendActions(for: .editingChanged)
        delegate?.textFieldDidChange?(self)
        if isSecureTextEntry {
            textView.text = maskSecurityText(text: textView.text)
        }
    }
}

extension Reactive where Base: CDTextField {

    var text: RxCocoa.ControlProperty<String?> {
        return controlProperty(editingEvents: .editingChanged, getter: { textField in
            textField.text
        }, setter: { textField, text in
            textField.text = text
        })
    }
    
    var title: RxCocoa.Binder<String?> {
        return base.titleLabel.rx.text
    }
    
    var theme: Binder<Theme> {
        return Binder(self.base) { textField, theme in
            textField.update(theme: theme)
        }
    }
}
