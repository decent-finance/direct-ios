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

import ReactorKit
import RxSwift
import RxCocoa

enum DocumentImage {
    case frontImage
    case backImage
    case selfieImage
}

enum DocumentType: String {
    
    case id = "nationalIdCard"
    case driverLicense = "driverLicense"
    case passport = "internationalPassport"
    
    var message: String {
        switch self {
        case .id:
            return NSLocalizedString("ID Card (both sides)", comment: "")
        case .driverLicense:
            return NSLocalizedString("Driver License (both sides)", comment: "")
        case .passport:
            return NSLocalizedString("Passport", comment: "")
        }
    }
    
    var selfieMessage: String {
        switch self {
        case .id:
            return NSLocalizedString("Selfie with Your ID Card", comment: "")
        case .driverLicense:
            return NSLocalizedString("Selfie with Your Driver License", comment: "")
        case .passport:
            return NSLocalizedString("Selfie with Your Passport", comment: "")
        }
    }
    
    var placeholderImage: UIImage? {
        let bundle = Bundle(for: UploadPhotoViewReactor.self)
        
        switch self {
        case .id:
            return UIImage(named: "id_photo_01_black", in: bundle, compatibleWith: nil)
        case .driverLicense:
            return UIImage(named: "drive_license_photo_front_black", in: bundle, compatibleWith: nil)
        case .passport:
            return UIImage(named: "passport_photo_01_black", in: bundle, compatibleWith: nil)
        }
    }
    
    var backPlaceholderImage: UIImage? {
        let bundle = Bundle(for: UploadPhotoViewReactor.self)
        
        switch self {
        case .id:
            return UIImage(named: "id_photo_back_black", in: bundle, compatibleWith: nil)
        case .driverLicense:
            return UIImage(named: "drive_license_photo_back", in: bundle, compatibleWith: nil)
        default:
            return nil
        }
    }
}

struct DocumentImages {
    
    var id: UIImage?
    var idBack: UIImage?
    var driverLicense: UIImage?
    var driverLicenseBack: UIImage?
    var passport: UIImage?
    
    func imageForDocumentType(_ documentType: DocumentType) -> UIImage? {
        switch documentType {
        case .id:
            return id
        case .driverLicense:
            return driverLicense
        case .passport:
            return passport
        }
    }
    
    func backImageForDocumentType(_ documentType: DocumentType) -> UIImage? {
        switch documentType {
        case .id:
            return idBack
        case .driverLicense:
            return driverLicenseBack
        default:
            return nil
        }
    }
    
    func imagesForDocumentType(_ documentType: DocumentType) -> [UIImage] {
        return [imageForDocumentType(documentType), backImageForDocumentType(documentType)].compactMap { $0 }
    }
    
    func areAllImagesSet(documentType: DocumentType) -> Bool {
        switch documentType {
        case .id, .driverLicense:
            return imagesForDocumentType(documentType).count == 2
        default:
            return imagesForDocumentType(documentType).count == 1
        }
    }
    
    mutating func setImage(_ image: UIImage?, documentType: DocumentType) {
        switch documentType {
        case .id:
            id = image
        case .driverLicense:
            driverLicense = image
        case .passport:
            passport = image
        }
    }
    
    mutating func setBackImage(_ image: UIImage?, documentType: DocumentType) {
        switch documentType {
        case .id:
            idBack = image
        case .driverLicense:
            driverLicenseBack = image
        default:
            break
        }
    }
}

class UploadPhotoViewReactor: Reactor {
    
    enum Action {
        case selectDocumentType(DocumentType)
        case uploadDocumentImage(UIImage)
        case uploadDocumentBackImage(UIImage)
        case uploadSelfieImage(UIImage)
        case checkUploadedImages
    }
    
    enum Mutation {
        case setDocumentType(DocumentType)
        case setDocumentImage(UIImage?)
        case setDocumentBackImage(UIImage?)
        case setSelfieImage(UIImage?)
        case setLoading(Bool)
        case setDocumentTypeError(String)
        case setDocumentErrors([DocumentImage]?)
    }
    
    struct State {
        var isDocumentRequired = false
        var documentType: DocumentType?
        var documentImage: UIImage?
        var documentBackImage: UIImage?
        var isSelfieRequired = false
        var selfieImage: UIImage?
        var areAllImagesUploaded = false
        var isLoading = false
        var documentErrors: [DocumentImage]?
        var documentTypeError: String?
    }
    
    var initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .selectDocumentType(type):
            return Observable.from([Mutation.setDocumentType(type), Mutation.setDocumentImage(images.imageForDocumentType(type)), Mutation.setDocumentBackImage(images.backImageForDocumentType(type))])
        case let .uploadDocumentImage(image):
            return mutateUploadDocumentImage(image)
        case let .uploadDocumentBackImage(image):
            return mutateUploadDocumentBackImage(image)
        case let .uploadSelfieImage(image):
            return mutateUploadSelfieImage(image)
        case .checkUploadedImages:
            return mutateCheckUploadedImages()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case let .setDocumentType(type):
            state = reduceDocumentType(state: state, documentType: type)
        case let .setDocumentImage(image):
            state = reduceDocumentImage(state: state, documentImage: image)
        case let .setDocumentBackImage(image):
            state = reduceBackDocumentImage(state: state, backDocumentImage: image)
        case let .setSelfieImage(image):
            state = reduceSelfieImage(state: state, selfieImage: image)
        case let .setLoading(isLoading):
            state.isLoading = isLoading
        case let .setDocumentTypeError(documentTypeError):
            state.documentTypeError = documentTypeError
        case let .setDocumentErrors(documentErrors):
            state.documentErrors = documentErrors
        }
        
        if let documentType = state.documentType {
            state.areAllImagesUploaded = (!state.isDocumentRequired || images.areAllImagesSet(documentType: documentType)) && (!state.isSelfieRequired || state.selfieImage != nil)
        }
        
        return state
    }
    
    private func reduceDocumentType(state: State, documentType: DocumentType) -> State {
        var result = state
        result.documentType = documentType
        result.documentTypeError = ""
        result.documentErrors = nil
        
        return result
    }
    
    private func reduceDocumentImage(state: State, documentImage: UIImage?) -> State {
        var result = state
        if documentImage != nil, let index = result.documentErrors?.firstIndex(of: .frontImage) {
            result.documentErrors?.remove(at: index)
        }
        
        result.documentImage = documentImage
        return result
    }
    
    private func reduceBackDocumentImage(state: State, backDocumentImage: UIImage?) -> State {
        var result = state
        if backDocumentImage != nil, let index = result.documentErrors?.firstIndex(of: .backImage) {
            result.documentErrors?.remove(at: index)
        }
        
        result.documentBackImage = backDocumentImage
        return result
    }
    
    private func reduceSelfieImage(state: State, selfieImage: UIImage?) -> State {
        var result = state
        if selfieImage != nil, let index = result.documentErrors?.firstIndex(of: .selfieImage) {
            result.documentErrors?.remove(at: index)
        }

        result.selfieImage = selfieImage
        return result
    }
    
    private func documentErrors() -> [DocumentImage] {
        var errorArray = [DocumentImage]()
        if currentState.isDocumentRequired {
            if currentState.documentImage == nil {
                errorArray.append(.frontImage)
            }
            
            if currentState.documentBackImage == nil && (currentState.documentType == .id || currentState.documentType == .driverLicense)  {
                errorArray.append(.backImage)
            }
        }
        if currentState.isSelfieRequired && currentState.selfieImage == nil {
            errorArray.append(.selfieImage)
        }
        return errorArray
    }
    
    init(serviceProvider: ServiceProvider, orderStore: OrderStore) {
        orderService = serviceProvider.orderService
        self.orderStore = orderStore
        
        var state = initialState
        state.isDocumentRequired = orderStore.order.isIdentityDocumentsRequired ?? false
        state.isSelfieRequired = orderStore.order.isSelfieRequired ?? false
        
        initialState = state
    }
    
    // MARK: - Implementation
    
    private let orderService: OrderService
    private let orderStore: OrderStore
    
    private var images = DocumentImages()
    
    private func mutateCheckUploadedImages() -> Observable<Mutation> {
        if currentState.documentType == nil {
            return .just(.setDocumentTypeError(NSLocalizedString("Please select document type", comment: "")))
        }
        
        if documentErrors().count > 0 {
            return .just(.setDocumentErrors(documentErrors()))
        }
     
        return .empty()
    }
    
    private func mutateUploadDocumentImage(_ image: UIImage) -> Observable<Mutation> {
        guard let documentType = currentState.documentType else { return .empty() }
        
        let oldImage = images.imageForDocumentType(documentType)
        images.setImage(image, documentType: documentType)
        
        return .concat(.from([Mutation.setLoading(true), .setDocumentImage(image)]), orderService.rx.uploadImages(images.imagesForDocumentType(documentType), documentType: documentType.rawValue, order: orderStore.order).map { .setDocumentImage(image) }.catchError { [unowned self] error -> Observable<Mutation> in
                self.images.setImage(oldImage, documentType: documentType)
                return .just(.setDocumentImage(oldImage))
            }, .just(Mutation.setLoading(false)))
    }
    
    private func mutateUploadDocumentBackImage(_ image: UIImage) -> Observable<Mutation> {
        guard let documentType = currentState.documentType else { return .empty() }
        
        let oldImage = images.backImageForDocumentType(documentType)
        images.setBackImage(image, documentType: documentType)
        
        return .concat(.from([Mutation.setLoading(true), Mutation.setDocumentBackImage(image)]), orderService.rx.uploadImages(images.imagesForDocumentType(documentType), documentType: documentType.rawValue, order: orderStore.order).map { .setDocumentBackImage(image) }.catchError { [unowned self] error -> Observable<Mutation> in
            self.images.setBackImage(oldImage, documentType: documentType)
            return .just(.setDocumentBackImage(oldImage))
        }, .just(Mutation.setLoading(false)))
    }
    
    private func mutateUploadSelfieImage(_ image: UIImage) -> Observable<Mutation> {
        let oldSelfieImage = currentState.selfieImage
        return .concat(.from([Mutation.setLoading(true), .setSelfieImage(image)]), orderService.rx.uploadImages([image], documentType: "selfie", order: orderStore.order).map { .setSelfieImage(image) }.catchErrorJustReturn(.setSelfieImage(oldSelfieImage)), .just(Mutation.setLoading(false)))
    }
}
