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
//  Created by Alex Kovalenko on 7/4/19.

import UIKit
import ReactorKit

class FooterViewReactor: Reactor {
    
    enum Action {
    }
    
    enum Mutation {
    }
    
    struct State {
        var rules: [Rule]
    }
    
    let initialState: State
    
    init(ruleStore: RulesStore) {
        initialState = State(rules: ruleStore.rules)
    }
}
