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
//  Created by Sergii Iastremskyi on 4/17/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import CocoaLumberjack

protocol UploadPhotoViewControllerDelegate: class {
    func scrollToDocumentTypeNotSelectedError()
    func scrollToDocumentErrorView(errorView: UIView)
    
    var areAllImagesUploadedSubject: BehaviorSubject<Bool>? { get }
    var loadingSubject: BehaviorSubject<Bool>? { get }
}

class UploadPhotoViewController: UIViewController, StoryboardView {
    
    weak var delegate: UploadPhotoViewControllerDelegate?
    let checkAllImagesUploadedSubject = PublishSubject<Void>()
    
    var disposeBag = DisposeBag()
    
    typealias Reactor = UploadPhotoViewReactor
    
    init() {
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(reactor: Reactor) {
        reactor.state.subscribe(onNext: { [unowned self] state in
            self.selectDocumentType(state.documentType)
            self.descriptionLabel.text = state.documentType?.message
            
            let documentImage = state.documentImage
            self.documentImageView.image = documentImage ?? state.documentType?.placeholderImage
            self.documentBackImageView.image = state.documentBackImage ?? state.documentType?.backPlaceholderImage
            self.selfieImageView.image = state.selfieImage ?? UIImage(named: "pic_portrait_card_photo_black", in: Bundle(for: type(of: self)), compatibleWith: nil)
            
            self.changeUploadButtonStyle(isUploadButtonShow: documentImage == nil, type: .frontImage)
            self.documentFrontTitleLabel.isHidden = state.documentType == .passport
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.documentType == nil || !$0.isDocumentRequired }
            .bind(to: documentView.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.documentImage == nil || $0.isDocumentRequired }
            .bind(to: documentErrorLabel.rx.isHidden, documentFrontErrorImageView.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.documentBackImage == nil || $0.isDocumentRequired }
            .bind(to: documentBackErrorLabel.rx.isHidden, documentBackErrorImageView.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.selfieImage == nil || $0.isSelfieRequired }
            .bind(to: selfieErrorLabel.rx.isHidden, selfieErrorImageView.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { ($0.documentType != .id && $0.documentType != .driverLicense) || !$0.isDocumentRequired }
            .bind(to: documentBackView.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.documentType == nil }
            .bind(to: documentDetailsView.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.documentType == nil || !$0.isSelfieRequired }
            .bind(to: selfieView.rx.isHidden)
            .disposed(by: disposeBag)
        
        checkAllImagesUploadedSubject.map { Reactor.Action.checkUploadedImages }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.documentTypeError }.subscribe (onNext: { [unowned self] documentTypeError in
            self.documentTypeErrorLabel.isHidden = documentTypeError.count == 0
            self.documentTypeErrorLabel.text = documentTypeError
            if !self.documentTypeErrorLabel.isHidden {
                self.delegate?.scrollToDocumentTypeNotSelectedError()
            }
        }).disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.documentErrors }.subscribe(onNext: { [unowned self] documentErrors in
            for error in documentErrors {
                self.showDocumentErrors(documentType: reactor.currentState.documentType, documentImage: error)
            }
            
            if let documentImage = documentErrors.first {
                self.delegate?.scrollToDocumentErrorView(errorView: self.documentErrorView(documentImage))
            }
        }).disposed(by: disposeBag)
        
        idTypeButton.rx.tap
            .map { Reactor.Action.selectDocumentType(.id) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        driverLicenseButton.rx.tap
            .map { Reactor.Action.selectDocumentType(.driverLicense) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        passportTypeButton.rx.tap
            .map { Reactor.Action.selectDocumentType(.passport) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        documentImageSubject.map { Reactor.Action.uploadDocumentImage($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        documentImageSubject.filter { [unowned self] _ in self.uploadedDocumentButtonView.isHidden }.subscribe(onNext: { [unowned self] _ in
            self.changeUploadButtonStyle(isUploadButtonShow: false, type: .frontImage)
        }).disposed(by: disposeBag)
        
        selfieImageSubject.map { Reactor.Action.uploadSelfieImage($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selfieImageSubject.filter { [unowned self] _ in self.uploadedSelfieButtonView.isHidden }.subscribe(onNext: { [unowned self] _ in
            self.changeUploadButtonStyle(isUploadButtonShow: false, type: .selfieImage)
        }).disposed(by: disposeBag)
        
        documentBackImageSubject.map { Reactor.Action.uploadDocumentBackImage($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        documentBackImageSubject.filter { [unowned self] _ in self.uploadedDocumentBackButtonView.isHidden }.subscribe(onNext: { [unowned self] _ in
            self.changeUploadButtonStyle(isUploadButtonShow: false, type: .backImage)
        }).disposed(by: disposeBag)
        
        if let loadingSubject = delegate?.loadingSubject {
            reactor.state.map { $0.isLoading }.distinctUntilChanged()
                .bind(to: loadingSubject)
                .disposed(by: disposeBag)
        }
        
        if let areAllImagesUploadedSubject = delegate?.areAllImagesUploadedSubject {
            reactor.state.map { $0.areAllImagesUploaded }.distinctUntilChanged()
                .bind(to: areAllImagesUploadedSubject)
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var idTypeButton: UIButton!
    @IBOutlet private weak var driverLicenseButton: UIButton!
    @IBOutlet private weak var passportTypeButton: UIButton!
    @IBOutlet private weak var documentTypeErrorLabel: UILabel!
    
    @IBOutlet private weak var documentView: UIStackView!
    @IBOutlet private weak var documentBackView: UIStackView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var documentImageView: UIImageView!
    @IBOutlet private weak var documentBackImageView: UIImageView!
    @IBOutlet private weak var documentErrorLabel: UILabel!
    @IBOutlet private weak var documentBackErrorLabel: UILabel!
    @IBOutlet private weak var selfieErrorLabel: UILabel!
    @IBOutlet private weak var documentDetailsView: UIStackView!
    @IBOutlet private weak var documentFrontErrorImageView: UIImageView!
    @IBOutlet private weak var documentBackErrorImageView: UIImageView!
    @IBOutlet private weak var selfieErrorImageView: UIImageView!
    @IBOutlet private weak var documentFrontTitleLabel: UILabel!
    
    @IBOutlet private weak var uploadDocumentButtonView: UIView!
    @IBOutlet private weak var uploadedDocumentButtonView: UIView!
    @IBOutlet private weak var uploadDocumentBackButtonView: UIView!
    @IBOutlet private weak var uploadedDocumentBackButtonView: UIView!
    @IBOutlet private weak var uploadSelfieButtonView: UIView!
    @IBOutlet private weak var uploadedSelfieButtonView: UIView!
    
    @IBOutlet private weak var selfieView: UIStackView!
    @IBOutlet private weak var selfieImageView: UIImageView!
    
    private let selectedTextColor = UIColor.cd_gray99
    private let selectedBorderColor = UIColor.cd_gray40
    
    private let unselectedTextColor = UIColor.cd_gray40
    private let unselectedBorderColor = UIColor.clear
    
    private var documentImageSubject = PublishSubject<UIImage>()
    private var documentBackImageSubject = PublishSubject<UIImage>()
    private var selfieImageSubject = PublishSubject<UIImage>()
    private var currentImageSubject: PublishSubject<UIImage>? = nil

    private func selectDocumentType(_ type: DocumentType?) {
        idTypeButton.setTitleColor((type == .id || type == nil) ? selectedTextColor : unselectedTextColor, for: .normal)
        idTypeButton.borderColor = (type == .id) ? unselectedBorderColor : selectedBorderColor
        idTypeButton.backgroundColor = (type == .id) ? .cd_gray30 : .cd_gray15
        
        driverLicenseButton.setTitleColor((type == .driverLicense || type == nil) ? selectedTextColor : unselectedTextColor, for: .normal)
        driverLicenseButton.borderColor = (type == .driverLicense) ? unselectedBorderColor : selectedBorderColor
        driverLicenseButton.backgroundColor = (type == .driverLicense) ? .cd_gray30 : .cd_gray15
        
        passportTypeButton.setTitleColor((type == .passport || type == nil) ? selectedTextColor : unselectedTextColor, for: .normal)
        passportTypeButton.borderColor = (type == .passport) ? unselectedBorderColor : selectedBorderColor
        passportTypeButton.backgroundColor = (type == .passport) ? .cd_gray30 : .cd_gray15
    }
    
    private func changeUploadButtonStyle(isUploadButtonShow: Bool, type: DocumentImage) {
        switch type {
        case .frontImage:
            uploadDocumentButtonView.isHidden = !isUploadButtonShow
            uploadedDocumentButtonView.isHidden = isUploadButtonShow
        case .backImage:
            uploadDocumentBackButtonView.isHidden = !isUploadButtonShow
            uploadedDocumentBackButtonView.isHidden = isUploadButtonShow
        case .selfieImage:
            uploadSelfieButtonView.isHidden = !isUploadButtonShow
            uploadedSelfieButtonView.isHidden = isUploadButtonShow
        }
    }
    
    @IBAction func uploadDocumentPhoto(_ sender: Any) {
        let sheetContainerController = instantiateBottomSheetViewController()
        let contentController = instantiateFindPhotoMenuViewController()
        sheetContainerController.setup(contentViewController: contentController)
        present(sheetContainerController, animated: true)
        
        currentImageSubject = documentImageSubject
    }
    
    @IBAction func uploadDocumentBackPhoto(_ sender: Any) {
        let sheetContainerController = instantiateBottomSheetViewController()
        let contentController = instantiateFindPhotoMenuViewController()
        sheetContainerController.setup(contentViewController: contentController)
        present(sheetContainerController, animated: true)
        
        currentImageSubject = documentBackImageSubject
    }
    
    @IBAction func uploadSelfie(_ sender: Any) {
        let sheetContainerController = instantiateBottomSheetViewController()
        let contentController = instantiateFindPhotoMenuViewController()
        sheetContainerController.setup(contentViewController: contentController)
        present(sheetContainerController, animated: true)
        
        currentImageSubject = selfieImageSubject
    }
    
    func instantiateBottomSheetViewController() -> CEXBottomSheetContainerController {
        let sheetContainerController = UIStoryboard(name: "CEXBottomSheetContainer", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as! CEXBottomSheetContainerController
        sheetContainerController.backgroundColor = UIColor.clear
        
        return sheetContainerController
    }
    
    func instantiateFindPhotoMenuViewController() -> FindPhotoMenuViewController {
        let result = FindPhotoMenuViewController()
        result.delegate = self
        
        return result
    }
    
    private func documentErrorView(_ documentImage: DocumentImage) -> UIView {
        switch documentImage {
        case .frontImage:
            return documentView
        case .backImage:
            return documentBackView
        case .selfieImage:
            return selfieView
        }
    }
    
    private func showDocumentErrors(documentType: DocumentType?, documentImage: DocumentImage) {
        guard let documentType = documentType else {
            return
        }
        
        switch documentType {
        case .id, .driverLicense:
            switch documentImage {
            case .frontImage:
                self.documentErrorLabel.isHidden = false
                self.documentFrontErrorImageView.isHidden = false
                self.documentErrorLabel.text = NSLocalizedString("Document front side is missing", comment: "")
            case .backImage:
                self.documentBackErrorLabel.isHidden = false
                self.documentBackErrorImageView.isHidden = false
                self.documentBackErrorLabel.text = NSLocalizedString("Document back side is missing", comment: "")
            case .selfieImage:
                self.selfieErrorLabel.isHidden = false
                self.selfieErrorImageView.isHidden = false
                self.selfieErrorLabel.text = NSLocalizedString("Selfie is missing", comment: "")
            }
        case .passport:
            switch documentImage {
            case .frontImage:
                self.documentErrorLabel.isHidden = false
                self.documentFrontErrorImageView.isHidden = false
                self.documentErrorLabel.text = NSLocalizedString("Document is missing", comment: "")
            case .backImage:
                break
            case .selfieImage:
                self.selfieErrorLabel.isHidden = false
                self.selfieErrorImageView.isHidden = false
                self.selfieErrorLabel.text = NSLocalizedString("Selfie is missing", comment: "")
            }
        }
    }
}

extension UploadPhotoViewController: FindPhotoMenuViewControllerDelegate {
    
    func photosDidTap(_ controller: FindPhotoMenuViewController) {
        dismiss(animated: true) {
            let imagePickerController = self.imagePicker(type: .photoLibrary)
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func cameraDidTap(_ controller: FindPhotoMenuViewController) {
        dismiss(animated: true) { [unowned self] in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePickerController = self.imagePicker(type: .camera)
                self.present(imagePickerController, animated: true, completion: nil)
            } else {
                self.cd_presentInfoAlert(message: NSLocalizedString("Device has no camera", comment: ""))
            }
        }
    }
    
    func imagePicker(type: UIImagePickerController.SourceType) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = type
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        return imagePickerController
    }
    
    func cancelPhotoDidTap(_ controller: FindPhotoMenuViewController) {
        dismiss(animated: true)
    }
}

extension UploadPhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage, let compressedImage = pickedImage.compressTo(15) else {
            DDLogError("Failed to pick image to upload")
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        currentImageSubject?.onNext(compressedImage)
        picker.dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    func compressTo(_ expectedSizeInMb: Int) -> UIImage? {
        let sizeInBytes = expectedSizeInMb * 1024 * 1024
        var needCompress: Bool = true
        var imageData: Data?
        var compressingValue: CGFloat = 1.0
        if let data = self.jpegData(compressionQuality: compressingValue), data.count < sizeInBytes {
            return self
        }
        
        compressingValue -= 0.1
        while (needCompress && compressingValue > 0.0) {
            if let data: Data = self.jpegData(compressionQuality: compressingValue) {
                if data.count < sizeInBytes {
                    needCompress = false
                    imageData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }
        
        if let data = imageData, data.count < sizeInBytes {
            return UIImage(data: data)
        }
        
        return nil
    }
}
