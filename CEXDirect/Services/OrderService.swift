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
//  Created by Ihor Vovk on 3/25/19.

import Foundation
import Alamofire
import CocoaLumberjack
import RxSwift
import CryptoSwift

public class OrderService: BaseService {
    
    init(session: Session, socketManager: SocketManager, placementID: String, secret: String, configuration: Configuration) {
        self.session = session
        self.socketManager = socketManager
        self.placementID = placementID
        self.secret = secret
        
        super.init(configuration: configuration)
    }

    func createOrder(order: Order, success: @escaping (Order) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let sourceURI = sourceURI, let email = order.email, let country = order.country, let fiatAmount = order.fiatAmount?.replaceComma(), let fiatCurrency = order.fiatCurrency, let cryptoAmount = order.cryptoAmount?.replaceComma(), let cryptoCurrency = order.cryptoCurrency {
            var data: Parameters = ["sourceUri": sourceURI, "userEmail": email, "country": country, "fiat": ["amount": fiatAmount, "currency": fiatCurrency], "crypto": ["amount": cryptoAmount, "currency": cryptoCurrency], "skipVerify": false]
            if let state = order.state {
                data["state"] = state
            }
            
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: data]
        }
        
        session.cd_requestObject(baseURL.appendingPathComponent("new"), method: Alamofire.HTTPMethod.put, parameters: parameters, encoding: JSONEncoding.default, keyPath: "data", success: { (responseOrder: Order) in
            var order = order
            order.orderID = responseOrder.orderID
            order.status = responseOrder.status
            success(order)
        }, failure: { error in
            if let error = error as? AFError, let responseCode = error.responseCode, responseCode == 475 {
                failure(ServiceError.locationNotSupported)
            } else {
                failure(error)
            }
        })
    }
    
    func loadOrderInfo(order: Order, success: @escaping (Order) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email {
            let nonce = self.nonce
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce)]]
        }
        
        session.cd_requestObject(baseURL.appendingPathComponent("info"), method: Alamofire.HTTPMethod.post, parameters: parameters, encoding: JSONEncoding.default, keyPath: "data", success: success, failure: failure)
    }
    
    func uploadImages(_ images: [UIImage], documentType: String, order: Order, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let base64Images = images.compactMap { $0.jpegData(compressionQuality: 1.0)?.base64EncodedString() }.enumerated().map { ["index": $0, "content": $1] }
        if base64Images.count < images.count {
            failure(ServiceError.incorrectParameters)
            return
        }
        
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email {
            let nonce = self.nonce
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce), "documentType": documentType, "base64image": base64Images]]
        }
        
        session.request(baseURL.appendingPathComponent("image"), method: .put, parameters: parameters, encoding: JSONEncoding.default).validate().response { response in
            if let error = response.error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func sendPaymentData(order: Order, success: @escaping (Order) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email, let cardBin = order.cardBin, let cardExpiryDate = order.cardExpiryDate, let walletAddress = order.walletAddress {
            let nonce = self.nonce
            var cryptoWallet: [String: String] = ["address": walletAddress]
            if let tag = order.walletTag {
                cryptoWallet["tag"] = tag
            }
            
            var data: [String: Any] = [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce), "termUrl": "https://devcexdirect.com:9443/api?direction", "paymentData": ["cardBin": cardBin, "cardExpired": cardExpiryDate, "cryptoWallet": cryptoWallet]]
            if let ssn = order.ssn {
                data["additional"] = ["billingSsn": ssn]
            }
            
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: data]
        }
        
        session.cd_requestObject(baseURL.appendingPathComponent("payment"), method: Alamofire.HTTPMethod.put, parameters: parameters, encoding: JSONEncoding.default, keyPath: "data", success: { (responseOrder: Order) in
            var order = order
            order.status = responseOrder.status
            order.additionalInfo = responseOrder.additionalInfo
            order.paymentConfirmationURL = responseOrder.paymentConfirmationURL
            success(order)
        }, failure: failure)
    }
    
    func updatePaymentData(order: Order, success: @escaping (Order) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email, let additionalInfo = order.additionalInfo {
            let nonce = self.nonce
            let additional = additionalInfo.compactMapValues { $0.value }
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce), "additional": additional]]
        }
        
        session.cd_requestObject(baseURL.appendingPathComponent("payment"), method: Alamofire.HTTPMethod.post, parameters: parameters, encoding: JSONEncoding.default, keyPath: "data", success: { (responseOrder: Order) in
            var order = order
            order.status = responseOrder.status
            order.paymentConfirmationURL = responseOrder.paymentConfirmationURL
            success(order)
        }, failure: failure)
    }
    
    func sendCardDataToVerification(order: Order, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let keyPair = CryptoDHKeyPair(group: CryptoDHGroup.group14)
        loadVerificationPublicKey(publicKey: keyPair.publicKey, order: order, success: { [weak self] verificationPublicKey, secretID in
            if let `self` = self, let sharedSecret = try? keyPair.createSharedSecret(publicKey: verificationPublicKey) {
                self.sendCardDataToVerification(order: order, secretID: secretID, sharedSecret: sharedSecret, success: success, failure: failure)
            } else {
                failure(ServiceError.incorrectResponseData)
            }
        }, failure: failure)
    }
    
    func sendCardDataToProcessing(order: Order, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let keyPair = CryptoDHKeyPair(group: CryptoDHGroup.group14)
        loadProcessingPublicKey(publicKey: keyPair.publicKey, order: order, success: { [weak self] verificationPublicKey, secretID in
            if let `self` = self, let sharedSecret = try? keyPair.createSharedSecret(publicKey: verificationPublicKey) {
                self.sendCardDataToProcessing(order: order, secretID: secretID, sharedSecret: sharedSecret, success: success, failure: failure)
            } else {
                failure(ServiceError.incorrectResponseData)
            }
        }, failure: failure)
    }
    
    func composePaymentConfirmationRequest(order: Order) -> URLRequest? {
        guard let urlString = order.paymentConfirmationURL, let url = URL(string: urlString), let templateBody = order.paymentConfirmationBody else {
            return nil
        }
        
        var body = templateBody
        if let orderID = order.orderID, let txID = order.paymentConfirmationTxID {
            body["TermUrl"] = baseURL.appendingPathComponent("3ds-check/\(orderID)/tx/\(txID)").absoluteString
        }
        
        var result = URLRequest(url: url)
        result.httpMethod = HTTPMethod.post.rawValue
        
        return try? URLEncoding.default.encode(result, with: body)
    }
    
    func checkConfirmationCode(code: String, order: Order, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID {
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, "confirmationCode": code]]
        }
        
        session.cd_request(baseURL.appendingPathComponent("check"), method: .post, parameters: parameters, success: { _ in
            success()
        }, failure: failure)
    }
    
    func updateEmail(newEmail: String, order: Order, success: @escaping (Order) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email {
            let nonce = self.nonce
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce), "newEmail": newEmail]]
        }
        
        session.cd_request(baseURL.appendingPathComponent("email"), method: .put, parameters: parameters, success: { _ in
            var order = order
            order.email = newEmail
            success(order)
        }, failure: failure)
    }
    
    func resendConfirmationCode(order: Order, success: @escaping (Order) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email {
            let nonce = self.nonce
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce)]]
        }
        
        session.cd_requestObject(baseURL.appendingPathComponent("resend-check-code"), method: .post, parameters: parameters, success: success, failure: failure)
    }
    
    func sendOpenedEvent(order: Order, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        var parameters: Parameters?
        if let sourceURI = sourceURI {
            let nonce = self.nonce
            
            var data: [String: Any] = ["sourceUri": sourceURI]
            if let fiatAmount = order.fiatAmount?.replaceComma(), let fiatCurrency = order.fiatCurrency {
                data["fiat"] = ["amount": fiatAmount, "currency": fiatCurrency]
            }
            
            if let cryptoAmount = order.cryptoAmount?.replaceComma(), let cryptoCurrency = order.cryptoCurrency {
                data["crypto"] = ["amount": cryptoAmount, "currency": cryptoCurrency]
            }
            
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: data]
        }
        
        session.cd_request(baseURL.appendingPathComponent("opened"), method: .put, parameters: parameters, encoding: JSONEncoding.default, success: { _ in
            success?()
        }, failure: { error in
            failure?(error)
        })
    }
    
    func sendBuyEvent(order: Order, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        var parameters: Parameters?
        if let sourceURI = sourceURI, let fiatAmount = order.fiatAmount?.replaceComma(), let fiatCurrency = order.fiatCurrency, let cryptoAmount = order.cryptoAmount?.replaceComma(), let cryptoCurrency = order.cryptoCurrency {
            let nonce = self.nonce
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: ["sourceUri": sourceURI, "fiat": ["amount": fiatAmount, "currency": fiatCurrency], "crypto": ["amount": cryptoAmount, "currency": cryptoCurrency]]]
        }
        
        session.cd_request(baseURL.appendingPathComponent("buy"), method: .put, parameters: parameters, encoding: JSONEncoding.default, success: { _ in
            success?()
        }, failure: { error in
            failure?(error)
        })
    }
    
    // MARK: - Implementation
    
    private let session: Session
    fileprivate let socketManager: SocketManager
    private let placementID: String
    private let secret: String
    private var baseURL: URL {
        return apiBaseURL.appendingPathComponent("orders")
    }
    
    fileprivate let orderIDKey = "orderId"
    fileprivate let orderSecretKey = "orderSecret"
    
    fileprivate func serviceData(nonce: Int) -> [String: Any] {
        let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let signature = (placementID + secret + String(nonce)).sha512()
        return ["nonce": nonce, "deviceFingerprint": identifierForVendor, "placementId": placementID, "signatureType": "msignature512", "signature": signature]
    }
    
    fileprivate func orderSecret(email: String, orderID: String, nonce: Int) -> String {
        return (email + orderID + String(nonce)).sha512().uppercased()
    }
    
    private func loadVerificationPublicKey(publicKey: String, order: Order, success: @escaping (_ publicKey: String, _ secretID: String) -> Void, failure: @escaping (Error) -> Void) {
        loadPublicKey(relativePath: "crypto/verification", publicKey: publicKey, order: order, success: success, failure: failure)
    }
    
    private func loadProcessingPublicKey(publicKey: String, order: Order, success: @escaping (_ publicKey: String, _ secretID: String) -> Void, failure: @escaping (Error) -> Void) {
        loadPublicKey(relativePath: "crypto/processing", publicKey: publicKey, order: order, success: success, failure: failure)
    }
    
    private func loadPublicKey(relativePath: String, publicKey: String, order: Order, success: @escaping (_ publicKey: String, _ secretID: String) -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email {
            let nonce = self.nonce
            parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce), "publicKey": publicKey]]
        }
        
        session.cd_request(baseURL.appendingPathComponent(relativePath), method: .post, parameters: parameters, encoding: JSONEncoding.default, success: { response in
            if let response = response as? [String: Any], let data = response["data"] as? [String: String], let publicKey = data["publicKey"], let secretID = data["secretId"] {
                success(publicKey, secretID)
            } else {
                failure(ServiceError.incorrectResponseData)
            }
        }, failure: failure)
    }
    
    private func sendCardDataToVerification(order: Order, secretID: String, sharedSecret: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let cardNumber = order.cardNumber, let cardExpiryDate = order.cardExpiryDate {
            sendEncryptedCardData(["cardNumber": cardNumber, "expirationDate": cardExpiryDate], relativePath: "send2verification", order: order, secretID: secretID, sharedSecret: sharedSecret, success: success, failure: failure)
        } else {
            failure(ServiceError.incorrectParameters)
        }
    }
    
    private func sendCardDataToProcessing(order: Order, secretID: String, sharedSecret: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let cardNumber = order.cardNumber, let cardCVV = order.cardCVV {
            sendEncryptedCardData(["cardNumber": cardNumber, "cvv": cardCVV], relativePath: "send2processing", order: order, secretID: secretID, sharedSecret: sharedSecret, success: success, failure: failure)
        } else {
            failure(ServiceError.incorrectParameters)
        }
    }
    
    private func sendEncryptedCardData(_ cardData: [String: String], relativePath: String, order: Order, secretID: String, sharedSecret: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        var parameters: Parameters?
        if let orderID = order.orderID, let email = order.email {
            if let encryptedCardData = try? Crypto.encrypt(cardData, sharedSecretKey: sharedSecret, secretId: secretID) {
                let nonce = self.nonce
                parameters = [serviceDataKey: serviceData(nonce: nonce), dataKey: [orderIDKey: orderID, orderSecretKey: orderSecret(email: email, orderID: orderID, nonce: nonce), "cardData": ["chash": encryptedCardData.encryptedValue, "rcid": encryptedCardData.initialVector], "channel" : "ios", "secretId": secretID]]
            }
        }
        
        session.cd_request(baseURL.appendingPathComponent(relativePath), method: .post, parameters: parameters, success: { _ in
            success()
        }, failure: failure)
    }
}

extension Reactive where Base : OrderService {
    
    func createOrder(order: Order) -> Observable<Order> {
        return Observable.create { observable in
            self.base.createOrder(order: order, success: { order in
                observable.onNext(order)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func uploadImages(_ images: [UIImage], documentType: String, order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.uploadImages(images, documentType: documentType, order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func sendPaymentData(order: Order) -> Observable<Order> {
        return Observable.create { observable in
            self.base.sendPaymentData(order: order, success: { order in
                observable.onNext(order)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func updatePaymentData(order: Order) -> Observable<Order> {
        return Observable.create { observable in
            self.base.updatePaymentData(order: order, success: { order in
                observable.onNext(order)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func sendCardDataToVerification(order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.sendCardDataToVerification(order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func sendCardDataToProcessing(order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.sendCardDataToProcessing(order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func checkConfirmationCode(code: String, order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.checkConfirmationCode(code: code, order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func updateEmail(newEmail: String, order: Order) -> Observable<Order> {
        return Observable.create { observable in
            self.base.updateEmail(newEmail: newEmail, order: order, success: { order in
                observable.onNext(order)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func resendConfirmationCode(order: Order) -> Observable<Order> {
        return Observable.create { observable in
            self.base.resendConfirmationCode(order: order, success: { order in
                observable.onNext(order)
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func subscribeOrderUpdates(order: Order) -> Observable<Order> {
        return base.socketManager.subscribe(event: "orderInfo") { [weak base] () -> SocketMessage in
            var messageData: [String: Any]? = nil
            if let base = base, let orderID = order.orderID, let email = order.email {
                let nonce = base.nonce
                messageData = [base.serviceDataKey: base.serviceData(nonce: nonce), base.dataKey: [base.orderIDKey: orderID, base.orderSecretKey: base.orderSecret(email: email, orderID: orderID, nonce: nonce)]]
            }
            
            return SocketMessage(event: "orderInfo", messageData: messageData)
        }.flatMap { message -> Observable<Order> in
            if let messageData = message.messageData as? [String: Any], let order = Order(JSON: messageData) {
                return .just(order)
            } else {
                return .empty()
            }
        }
    }
    
    func sendOpenedEvent(order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.sendOpenedEvent(order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    func sendBuyEvent(order: Order) -> Observable<Void> {
        return Observable.create { observable in
            self.base.sendBuyEvent(order: order, success: {
                observable.onNext(())
                observable.onCompleted()
            }, failure: { error in
                observable.onError(error)
            })
            
            return Disposables.create()
        }
    }
}
