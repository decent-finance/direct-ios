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
//  Created by Ihor Vovk on 4/14/19.

import UIKit
import RxSwift
import RxCocoa

protocol CDPickerButtonDelegate: class {
    
    func pickerButtonDidTap(_ button: CDPickerButton)
}

/*@IBDesignable*/ class CDPickerButton: UIControl {

    @IBInspectable var icon: String? = nil {
        didSet {
            if let icon = icon {
                iconImageView.image = UIImage(named: icon, in: Bundle(for: type(of: self)), compatibleWith: nil)
            } else {
                iconImageView.image = nil
            }
            
            iconImageView.isHidden = (iconImageView.image == nil)
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
    
    @IBInspectable var showChevron: Bool {
        get {
            return !chevronImageView.isHidden
        }
        
        set(newShowChevron) {
            chevronImageView.isHidden = !newShowChevron
        }
    }
    
    @IBInspectable var flipChevronOnTap: Bool = false
    
    weak var delegate: CDPickerButtonDelegate?
    
    var selection: String? {
        get {
            return selectionLabel.text
        }
        
        set(newSelection) {
            if newSelection != selection {
                selectionLabel.text = newSelection
                update(theme: .dark)
            }
        }
    }
    
    var error: String? {
        didSet {
            update(theme: .dark)
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
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var selectionLabel: UILabel!
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet fileprivate weak var button: UIButton!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var borderView: UIView!
    
    @IBAction private func buttonDidTap(_ sender: Any) {
        delegate?.pickerButtonDidTap(self)
        if flipChevronOnTap {
            flipChevron()
        }
    }
    
    private func setUp() {
        cd_loadContentFromNib()
        update(theme: .dark)
    }
    
    fileprivate func update(theme: Theme) {
        borderColor = (theme == .dark) ? .cd_gray40 : .clear
        
        iconImageView.isHidden = (iconImageView.image == nil)
        
        if let selection = selectionLabel.text, selection.count > 0 {
            titleLabel.textColor = (theme == .dark) ? .cd_gray70 : .cd_gray5
            titleLabel.font = self.titleLabel.font.withSize(12)
            
            selectionLabel.isHidden = false
        } else {
            titleLabel.textColor = (theme == .dark) ? .cd_white : .cd_gray20
            self.titleLabel.font = self.titleLabel.font.withSize(16)
            
            selectionLabel.isHidden = true
        }
        
        if error != nil {
            borderView.borderColor = .cd_redNormal
        } else {
            borderView.borderColor = (theme == .dark) ? .cd_gray40 : .clear
        }
        
        errorLabel?.text = error
        errorLabel?.isHidden = error == nil || error?.count == 0
    }
    
    private func flipChevron() {
        UIView.animate(withDuration: 0.2) {
            if self.chevronImageView.transform == CGAffineTransform.identity {
                self.chevronImageView.transform = CGAffineTransform(scaleX: 1, y: -1)
            } else {
                self.chevronImageView.transform = CGAffineTransform.identity
            }
        }
    }
}

extension Reactive where Base : CDPickerButton {
    
    var selection: RxCocoa.ControlProperty<String?> {
        return controlProperty(editingEvents: .valueChanged, getter: { pickerButton in
            pickerButton.selection
        }, setter: { pickerButton, selection in
            pickerButton.selection = selection
        })
    }
    
    var tap: RxCocoa.ControlEvent<Void> {
        return base.button.rx.tap
    }
}
