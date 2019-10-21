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

/*@IBDesignable*/ class CDButton: UIControl {
    
    enum Style: String {
        
        case gray = "gray"
        case blue = "blue"
        case clear = "clear"
    }
    
    struct StyleInfo {
        
        let backgroundColor: UIColor
        let activeBackgroundColor: UIColor
        let disabledBackgroundColor: UIColor
        let titleColor: UIColor
        let activeTitleColor: UIColor
        let disabledTitleColor: UIColor
        let titleFontName: String
        let imageName: String?
    }
    
    @IBInspectable var style: String? {
        didSet {
            update(theme: .dark)
        }
    }
    
    @IBInspectable var title: String? {
        get {
            return button.title(for: .normal)
        }
        
        set(newTitle) {
            button.setTitle(newTitle, for: .normal)
        }
    }
    
    @IBInspectable var fontSize: CGFloat {
        get {
            return button.titleLabel?.font.pointSize ?? 0
        }
        
        set(newSize) {
            if let font = button.titleLabel?.font {
                button.titleLabel?.font = UIFont(name: font.fontName, size: newSize)
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            button.isEnabled = isEnabled
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            button.isHighlighted = isHighlighted
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
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setNeedsDisplay()
    }
    
    // MARK: - Implementation
    
    @IBOutlet fileprivate weak var button: UIButton!
    
    private func setUp() {
        cd_loadContentFromNib()
        update(theme: .dark)
    }
    
    private func update(theme: Theme) {
        guard let styleInfo = styleInfo(theme: theme) else { return }
        if let imageName = styleInfo.imageName {
            let image = UIImage(named: imageName, in: Bundle(for: type(of: self)), compatibleWith: nil)
            button.setBackgroundImage(image, for: .normal)
        } else {
            button.cd_setBackgroundColor(color: styleInfo.backgroundColor, state: .normal)
        }
        button.cd_setBackgroundColor(color: styleInfo.activeBackgroundColor, state: .highlighted)
        button.cd_setBackgroundColor(color: styleInfo.disabledBackgroundColor, state: .disabled)
        
        button.setTitleColor(styleInfo.titleColor, for: .normal)
        button.setTitleColor(styleInfo.activeTitleColor, for: .highlighted)
        button.setTitleColor(styleInfo.disabledTitleColor, for: .disabled)
        button.titleLabel?.font = UIFont(name: styleInfo.titleFontName, size: fontSize)
    }
    
    private func styleInfo(theme: Theme) -> StyleInfo? {
        guard let rawStyle = style, let style = Style(rawValue: rawStyle) else { return nil }
        
        switch theme {
        case .dark:
            switch style {
            case .gray:
                return StyleInfo(backgroundColor: .cd_gray30, activeBackgroundColor: .cd_gray30, disabledBackgroundColor: .cd_gray30, titleColor: .cd_white, activeTitleColor: .cd_white, disabledTitleColor: .cd_white, titleFontName: "OpenSans", imageName: nil)
            case .blue:
                return StyleInfo(backgroundColor: .cd_brandingNormal, activeBackgroundColor: .cd_gray20Transparent, disabledBackgroundColor: .cd_gray30, titleColor: .cd_white, activeTitleColor: .cd_whiteTransparent, disabledTitleColor: .cd_whiteTransparent, titleFontName: "OpenSans-Extrabold", imageName: "shape_button")
            case .clear:
                return StyleInfo(backgroundColor: .clear, activeBackgroundColor: .clear, disabledBackgroundColor: .clear, titleColor: .cd_white, activeTitleColor: .cd_white, disabledTitleColor: .cd_white, titleFontName: "OpenSans", imageName: nil)
            }
        case .light:
            switch style {
            case .gray:
                return StyleInfo(backgroundColor: .cd_gray30, activeBackgroundColor: .cd_gray30, disabledBackgroundColor: .cd_gray30, titleColor: .cd_white, activeTitleColor: .cd_white, disabledTitleColor: .cd_white, titleFontName: "OpenSans", imageName: nil)
            case .blue:
                return StyleInfo(backgroundColor: .cd_brandingNormal, activeBackgroundColor: .cd_gray20Transparent, disabledBackgroundColor: .cd_gray30, titleColor: .cd_white, activeTitleColor: .cd_whiteTransparent, disabledTitleColor: .cd_whiteTransparent, titleFontName: "OpenSans-Extrabold", imageName: "shape_button")
            case .clear:
                return StyleInfo(backgroundColor: .clear, activeBackgroundColor: .clear, disabledBackgroundColor: .clear, titleColor: .cd_white, activeTitleColor: .cd_white, disabledTitleColor: .cd_white, titleFontName: "OpenSans", imageName: nil)
            }
        }
    }
    
    @IBAction private func touch(_ sender: Any) {
        sendActions(for: .touchUpInside)
    }
}

extension Reactive where Base : CDButton {
    
    var tap: RxCocoa.ControlEvent<Void> {
        return controlEvent(.touchUpInside)
    }
    
    func title(for controlState: UIControl.State = .normal) -> RxCocoa.Binder<String?> {
        return base.button.rx.title(for: controlState)
    }
}

