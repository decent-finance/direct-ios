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
//  Created by Ihor Vovk on 7/17/18 4:26 PM.

import UIKit

@objc extension UIColor {

    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = (hex >> 16) & 0xFF
        let green = (hex >> 8) & 0xFF
        let blue = (hex) & 0xFF
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    class var cd_gray5: UIColor { return UIColor(hex: 0x06090D) }
    class var cd_gray10: UIColor { return UIColor(hex: 0x0D111A) }
    class var cd_gray15: UIColor { return UIColor(hex: 0x131926) }
    class var cd_gray20: UIColor { return UIColor(hex: 0x1D2B40) }
    class var cd_gray30: UIColor { return UIColor(hex: 0x26374D) }
    class var cd_gray40: UIColor { return UIColor(hex: 0x3D4E66) }
    class var cd_gray50: UIColor { return UIColor(hex: 0x536580) }
    class var cd_gray60: UIColor { return UIColor(hex: 0x677C99) }
    class var cd_gray70: UIColor { return UIColor(hex: 0x7D93B3) }
    class var cd_gray80: UIColor { return UIColor(hex: 0xA3B4CC) }
    class var cd_gray85: UIColor { return UIColor(hex: 0xBDC8D9) }
    class var cd_gray90: UIColor { return UIColor(hex: 0xCFD8E6) }
    class var cd_gray95: UIColor { return UIColor(hex: 0xE1E8F2) }
    class var cd_gray98: UIColor { return UIColor(hex: 0xF0F4FA) }
    class var cd_gray99: UIColor { return UIColor(hex: 0xF9FBFC) }
    
    class var cd_white: UIColor { return UIColor(hex: 0xFFFFFF) }
    class var cd_brandingNormal: UIColor { return UIColor(hex: 0x0C87F2) }
    class var cd_redNormal: UIColor { return UIColor(hex: 0xE65069) }
    
    class var cd_gray20Transparent: UIColor { return UIColor(hex: 0x1D2B40, alpha: 0.3) }
    class var cd_whiteTransparent: UIColor { return UIColor(hex: 0xFFFFFF, alpha: 0.5) }
    
    class var cd_circleColor: UIColor { return UIColor(hex: 0xDEE0E2) }
    class var cd_circleFillColor: UIColor { return UIColor(hex: 0x4DD8DF) }
}
