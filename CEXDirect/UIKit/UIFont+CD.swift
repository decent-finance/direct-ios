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

import Foundation

import UIKit
import CocoaLumberjack

extension UIFont {
    
    static func cd_registerCustomFonts() {
        cd_registerCustomFont(name: "OpenSans-Regular")
        cd_registerCustomFont(name: "OpenSans-ExtraBold")
    }
    
    // MARK: - Implementation
    
    static private func cd_registerCustomFont(name: String) {
        guard let url = Bundle(identifier: "io.cex.framework.CEXDirect")?.url(forResource: name, withExtension: "ttf") else { return }
        
        if let fontDataProvider = CGDataProvider(url: url as CFURL), let font = CGFont(fontDataProvider) {
            CTFontManagerRegisterGraphicsFont(font, nil)
        }
    }
    
    class var cd_T16R: UIFont { return UIFont(name: "OpenSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16) }
    class var cd_T16EB: UIFont { return UIFont(name: "OpenSans-ExtraBold", size: 16) ?? UIFont.systemFont(ofSize: 16) }
}
