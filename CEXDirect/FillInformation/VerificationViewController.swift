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
//  Created by Ihor Vovk on 11/18/19.

import UIKit
import Lottie

class VerificationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animationView.imageProvider = AssetsAnimationImageProvider()
        animationView.loopMode = .loop
        if let asset = NSDataAsset(name: "verification", bundle: Bundle(for: type(of: self))) {
            animationView.animation = try? JSONDecoder().decode(Animation.self, from: asset.data)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animationView.play()
        progressView.startAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        animationView.stop()
        progressView.stopAnimation()
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var animationView: AnimationView!
    @IBOutlet private weak var progressView: CDProgressView!
}
