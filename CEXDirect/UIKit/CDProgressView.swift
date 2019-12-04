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
//  Created by Alexandr Kovalenko on 10/28/19.

import UIKit

/*@IBDesignable*/ class CDProgressView: UIView, CAAnimationDelegate {
    
    @IBInspectable var animationDuration: Double = 1.5
    
    @IBInspectable var lineWidth: CGFloat = 3 {
        didSet {
            setUp()
        }
    }
    
    @IBInspectable var addReversePhase: Bool = true {
        didSet {
            setUp()
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
    
    private let firstArcLayer = CAShapeLayer()
    private let secondArcLayer = CAShapeLayer()
    
    private var isAnimationInProgress = false
    
    private func setUp() {
        layer.sublayers = nil
        
        let center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
        let circularPath = UIBezierPath(arcCenter: center, radius: (self.bounds.width - lineWidth) / 2, startAngle: -.pi / 2, endAngle: .pi + .pi / 2, clockwise: true)
    
        let circleLayer = CAShapeLayer()
        circleLayer.path = circularPath.cgPath
        circleLayer.strokeColor = addReversePhase ? UIColor.cd_circleColor.cgColor : UIColor.clear.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = lineWidth
        layer.addSublayer(circleLayer)
        
        firstArcLayer.path = circularPath.cgPath
        firstArcLayer.strokeColor = UIColor.cd_circleFillColor.cgColor
        firstArcLayer.fillColor = UIColor.clear.cgColor
        firstArcLayer.lineWidth = lineWidth
        firstArcLayer.strokeEnd = 0
        layer.addSublayer(firstArcLayer)
        
        secondArcLayer.path = circularPath.cgPath
        secondArcLayer.strokeColor = addReversePhase ? UIColor.cd_circleColor.cgColor : UIColor.clear.cgColor
        secondArcLayer.fillColor = UIColor.clear.cgColor
        secondArcLayer.lineWidth = lineWidth
        secondArcLayer.strokeEnd = 0
        layer.addSublayer(secondArcLayer)
    }
    
    func startAnimation() {
        startFirstAnimation()
    }
    
    func stopAnimation() {
        isAnimationInProgress = false
        firstArcLayer.removeAllAnimations()
        secondArcLayer.removeAllAnimations()
    }
    
    private func startFirstAnimation() {
        if isAnimationInProgress {
            return
        }
        
        isAnimationInProgress = true
        firstArcLayer.add(arcAnimation(), forKey: "firstArcAnimation")
    }
    
    private func startSecondAnimation() {
        secondArcLayer.add(arcAnimation(), forKey: "secondArcAnimation")
    }
    
    private func arcAnimation() -> CABasicAnimation {
        let arcAnimation = CABasicAnimation(keyPath: "strokeEnd")
        arcAnimation.fromValue = 0
        arcAnimation.duration = animationDuration
        arcAnimation.toValue = 1
        arcAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        arcAnimation.isRemovedOnCompletion = false
        arcAnimation.fillMode = .forwards
        arcAnimation.delegate = self
        
        return arcAnimation
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isAnimationInProgress {
            if anim == firstArcLayer.animation(forKey: "firstArcAnimation") && addReversePhase {
                self.layer.insertSublayer(secondArcLayer, above: firstArcLayer)
                startSecondAnimation()
            } else {
                isAnimationInProgress = false
                self.layer.insertSublayer(firstArcLayer, above: secondArcLayer)
                startFirstAnimation()
            }
        }
    }
}
