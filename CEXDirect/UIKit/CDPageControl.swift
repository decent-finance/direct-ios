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
//  Created by Alex Kovalenko on 4/17/19.

import UIKit
import RxSwift
import RxCocoa

/*@IBDesignable*/ class CDPageControl: UIControl {

    @IBOutlet weak var stackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    @IBInspectable var externalCircleColor: UIColor = .cd_brandingNormal {
        didSet {
            updateNumberOfPages(numberOfPages)
        }
    }
    
    @IBInspectable var circleColor: UIColor = .cd_gray40 {
        didSet {
            updateNumberOfPages(numberOfPages)
        }
    }
    
    @IBInspectable var selectedCircleColor: UIColor = .cd_brandingNormal {
        didSet {
            updateCurrentPage(currentPage)
        }
    }
    
    @IBInspectable var circleDiameter: CGFloat = 18 {
        didSet {
            updateNumberOfPages(numberOfPages)
        }
    }
    
    @IBInspectable var circleBetweenSize: CGFloat = 8 {
        didSet {
            updateNumberOfPages(numberOfPages)
        }
    }
    
    @IBInspectable var circleBorderWidth: CGFloat = 1 {
        didSet {
            updateNumberOfPages(numberOfPages)
        }
    }
    
    @IBInspectable var numberOfPages: Int = 4 {
        didSet {
            updateNumberOfPages(numberOfPages)
            self.isHidden = numberOfPages <= 1
        }
    }
    
    @IBInspectable var currentPage: Int = 0 {
        didSet {
            updateCurrentPage(currentPage)
        }
    }
    
    var shownPage: Int = 0 {
        didSet {
            updateCurrentPage(currentPage)
        }
    }
    
    // MARK: - Implementation
    
    private func setUp() {
        cd_loadContentFromNib()
        
        updateNumberOfPages(numberOfPages)
    }
    
    private func updateNumberOfPages(_ count: Int) {
        
        if count < 0 {
            return
        }
        
        for subView in stackView.arrangedSubviews {
            subView.removeFromSuperview()
        }
        
        for _ in 0 ..< count {
            
            let whiteView = UIView()
            whiteView.widthAnchor.constraint(equalToConstant: circleDiameter).isActive = true
            whiteView.heightAnchor.constraint(equalToConstant: circleDiameter).isActive = true
            
            let circleView = UIView()
            circleView.layer.borderWidth = circleBorderWidth
            circleView.layer.borderColor = externalCircleColor.cgColor
            circleView.layer.cornerRadius = circleDiameter / 2
            circleView.isHidden = true
            
            whiteView.addSubview(circleView)
            
            circleView.translatesAutoresizingMaskIntoConstraints = false
            whiteView.addConstraints([
                NSLayoutConstraint(item: circleView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: whiteView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: circleView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: whiteView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: circleView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: whiteView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: circleView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: whiteView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
                ])
            
            let centerCircleView = UIView()
            centerCircleView.backgroundColor = circleColor
            centerCircleView.layer.cornerRadius = (circleDiameter - circleBetweenSize) / 2
            
            whiteView.addSubview(centerCircleView)
            
            centerCircleView.translatesAutoresizingMaskIntoConstraints = false
            centerCircleView.widthAnchor.constraint(equalToConstant: circleDiameter - circleBetweenSize).isActive = true
            centerCircleView.heightAnchor.constraint(equalToConstant: circleDiameter - circleBetweenSize).isActive = true
            centerCircleView.centerXAnchor.constraint(equalTo: whiteView.centerXAnchor).isActive = true
            centerCircleView.centerYAnchor.constraint(equalTo: whiteView.centerYAnchor).isActive = true
            
            stackView.addArrangedSubview(whiteView)
        }
        
        updateCurrentPage(currentPage)
    }
    
    private func updateCurrentPage(_ currentPage: Int) {
        
        if currentPage > numberOfPages {
            return
        }
        
        defaultState()
        
        let view = stackView.arrangedSubviews[currentPage]
        if let externalCircle = view.subviews.first {
            externalCircle.isHidden = false
        }
        
        for i in 0 ... currentPage {
            let view = stackView.arrangedSubviews[i]
            
            if i <= shownPage, let centerCircle = view.subviews.last {
                centerCircle.backgroundColor = selectedCircleColor
            }
        }
        
    }
    
    private func defaultState() {
        for i in 0 ... numberOfPages - 1 {
            let view = stackView.arrangedSubviews[i]
            
            if let externalCircle = view.subviews.first {
                externalCircle.isHidden = true
            }
            
//            if let centerCircle = view.subviews.last {
//                centerCircle.backgroundColor = circleColor
//            }
        }
    }

}

extension Reactive where Base : CDPageControl {
    
    var currentPage: RxCocoa.Binder<Int> {
        return Binder(base, binding: { (pageControl, page) in
            pageControl.currentPage = page
        })
    }
}
