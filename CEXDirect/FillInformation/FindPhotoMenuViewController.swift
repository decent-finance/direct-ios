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
//  Created by Sergii Iastremskyi on 4/18/19.

import UIKit
import RxSwift
import RxCocoa

protocol FindPhotoMenuViewControllerDelegate: class {
    
    func photosDidTap(_ controller: FindPhotoMenuViewController)
    func cameraDidTap(_ controller: FindPhotoMenuViewController)
    func cancelPhotoDidTap(_ controller: FindPhotoMenuViewController)
}

class FindPhotoMenuViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
    }
    
    var disposeBag = DisposeBag()
    weak var delegate: FindPhotoMenuViewControllerDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        photosButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.photosDidTap(self)
        }).disposed(by: disposeBag)
        
        cameraButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.cameraDidTap(self)
        }).disposed(by: disposeBag)
        
        cancelButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.cancelPhotoDidTap(self)
        }).disposed(by: disposeBag)
    }
    
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
}
