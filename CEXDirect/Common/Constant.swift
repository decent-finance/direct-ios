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
//  Created by Alex Kovalenko on 5/16/19.

import UIKit

struct Constant {
    
    struct Card {
        static let CardNumberLenght = 16
        static let CvvNumberLenght = 4
    }
    
    struct SSN {
        static let dashIndexes = [3, 6]
        static let length = 11
    }
    
    struct PageTitle {
        static let IndentSize: CGFloat = 20
    }
    
    struct ConfirmEmail {
        static let resendCodeTime = 120
    }
    
    struct CDCheckbox {
        static let startRuleText = NSLocalizedString("I agree with ", comment: "") 
    }
}
