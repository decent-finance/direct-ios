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
//  Created by Ihor Vovk on 4/3/19.

import Foundation
import ObjectMapper
import RxSwift

public struct Order: Mappable {
    
    enum Status: String {
        
        case uncompleted = "uncomplited"
        case ivsReady = "ivs-ready"
        case ivsPending = "ivs-pending"
        case ivsFailed = "ivs-failed"
        case ivsRejected = "ivs-rejected"
        case ivsSuccess = "ivs-success"
        case pssWaitData = "pss-waitdata"
        case pssReady = "pss-ready"
        case pssPending = "pss-pending"
        case pssFailed = "pss-failed"
        case pssRejected = "pss-rejected"
        case pss3dsRequired = "pss-3ds-required"
        case pss3dsPending = "pss-3ds-pending"
        case pssSuccess = "pss-success"
        case waitingForConfirmation = "waiting-for-confirmation"
        case completed
        case finished
        case rejected
        
        case new = "new"
        case verificationReady = "verification-ready"
        case verificationInProgress = "verification-in-progress"
        case verificationSuccess = "verification-success"
        case verificationRejected = "verification-rejected"
        case verificationFailed = "verification-failed"
        case processingAcknowledge = "processing-acknowledge"
        case processingReady = "processing-ready"
        case processingInProgress = "processing-in-progress"
        case processing3ds = "processing-3ds"
        case processing3dsPending = "processing-3ds-pending"
        case processingSuccess = "processing-success"
        case processingRejected = "processing-rejected"
        case processingFailed = "processing-failed"
        case refundInProgress = "refund-in-progress"
        case refunded = "refunded"
        case emailConfirmation = "email-confirmation"
        case cryptoSending = "crypto-sending"
        case cryptoSent = "crypto-sent"
        case settled = "settled"
        case crashed = "crashed"
    }
    
    enum AdditionalInfoKey: String, CaseIterable {
        
        case userFirstName
        case userLastName
        case userMiddleName
        case userDateOfBirth
        case userResidentialCountry
        case billingState
        case userResidentialCity
        case userResidentialStreet
        case userResidentialAptSuite
        case userResidentialPostcode
        case userResidentialPostcodeUK
        case userRuPassport
        case userRuPassportIssueDate
        case userRuPassportIssuedBy
        case userRuPhone
        case billingCounty
        case billingCity
        case billingStreet
        case billingZipCode
        case billingSsn
        
        func errorMessage(country: String?) -> String {
            switch self {
            case .userFirstName:
                return NSLocalizedString("Please enter first name", comment: "")
            case .userLastName:
                return NSLocalizedString("Please enter last name", comment: "")
            case .userMiddleName:
                return NSLocalizedString("Please enter middle name", comment: "")
            case .userDateOfBirth:
                return NSLocalizedString("Please enter a valid date of birth", comment: "")
            case .userResidentialCountry:
                return NSLocalizedString("Please enter a valid country", comment: "")
            case .billingState:
                return NSLocalizedString("Please enter a valid state", comment: "")
            case .userResidentialCity:
                return NSLocalizedString("Please enter a valid city", comment: "")
            case .userResidentialStreet:
                return NSLocalizedString("Please enter a valid street address", comment: "")
            case .userResidentialAptSuite:
                return NSLocalizedString("Please enter a valid apt./suite", comment: "")
            case .userResidentialPostcode:
                // Workaround for backend issues
                if country == "US" {
                    return NSLocalizedString("Please enter a valid ZIP code", comment: "")
                } else {
                    return NSLocalizedString("Please enter a valid postcode", comment: "")
                }
            case .userResidentialPostcodeUK:
                return NSLocalizedString("Please enter a valid postcode", comment: "")
            case .userRuPassport:
                return NSLocalizedString("Please enter a valid passport number", comment: "")
            case .userRuPassportIssueDate:
                return NSLocalizedString("Please enter a valid date", comment: "")
            case .userRuPassportIssuedBy:
                return NSLocalizedString("Please enter a valid street address", comment: "")
            case .userRuPhone:
                return NSLocalizedString("Please enter a valid phone", comment: "")
            case .billingCounty:
                return NSLocalizedString("Please enter a valid country", comment: "")
            case .billingCity:
                return NSLocalizedString("Please enter a valid city", comment: "")
            case .billingStreet:
                return NSLocalizedString("Please enter a valid street address", comment: "")
            case .billingZipCode:
                return NSLocalizedString("Please enter a valid ZIP code", comment: "")
            case .billingSsn:
                return NSLocalizedString("Please enter a valid SSN", comment: "")
            }
        }
    }

    struct AdditionalInfo: Mappable {
        
        var value: String?
        var isRequired: Bool = false
        var isEditable: Bool = true
        
        init?(map: Map){
        }
        
        mutating func mapping(map: Map) {
            value <- map["value"]
            isRequired <- map["req"]
            isEditable <- map["editable"]
        }
    }
    
    var orderID: String?
    var merchantOrderID: String?
    var status: Status?
    
    var fiatAmount: String?
    var fiatCurrency: String?
    
    var cryptoAmount: String?
    var cryptoCurrency: String?
    
    var cardNumber: String?
    var cardExpiryDate: String?
    var cardCVV: String?
    
    var cardBin: String? {
        if let cardNumber = cardNumber {
            return String(cardNumber.suffix(4))
        } else {
            return nil
        }
    }
    
    var walletAddress: String?
    var walletTag: String?
    
    var email: String?
    var country: String?
    var state: String?
    var ssn: String?
    
    var isIdentityDocumentsRequired: Bool?
    var isSelfieRequired: Bool?
    
    var areTermsAndPolicyAccepted: Bool?
    
    var additionalInfo: [String: AdditionalInfo]?
    
    var paymentConfirmationTxID: String?
    var paymentConfirmationURL: String?
    var paymentConfirmationBody: [String : String]?
    
    var txID: String?
    
    init() {
    }
    
    public init?(map: Map){
    }
    
    mutating public func mapping(map: Map) {
        orderID <- map["orderId"]
        merchantOrderID <- map["merchOrderId"]
        status <- map["orderStatus"]
        
        fiatAmount <- map["basic.fiat.amount"]
        fiatCurrency <- map["basic.fiat.currency"]
        
        cryptoAmount <- map["basic.crypto.amount"]
        cryptoCurrency <- map["basic.crypto.currency"]
        
        walletAddress <- map["basic.wallet.address"]
        walletTag <- map["basic.wallet.tag"]
        
        email <- map["userEmail"]
        country <- map["country"]
        state <- map["state"]
        ssn <- map["ssn"]
        
        isIdentityDocumentsRequired <- map["basic.images.isIdentityDocumentsRequired"]
        isSelfieRequired <- map["basic.images.isSelfieRequired"]
        
        additionalInfo <- map["additional"]

        paymentConfirmationTxID <- map["threeDS.txId"]
        paymentConfirmationURL <- map["threeDS.url"]
        paymentConfirmationBody <- map["threeDS.data"]
        
        txID <- map["paymentInfo.txId"]
    }
    
    func update(order: Order) -> Order {
        var result = self
        
        if let orderID = order.orderID {
            result.orderID = orderID
        }
        
        if let merchantOrderID = order.merchantOrderID {
            result.merchantOrderID = merchantOrderID
        }
        
        if let status = order.status {
            result.status = status
        }
        
        if let fiatAmount = order.fiatAmount {
            result.fiatAmount = fiatAmount
        }
        
        if let fiatCurrency = order.fiatCurrency {
            result.fiatCurrency = fiatCurrency
        }
        
        if let cryptoAmount = order.cryptoAmount {
            result.cryptoAmount = cryptoAmount
        }
        
        if let cryptoCurrency = order.cryptoCurrency {
            result.cryptoCurrency = cryptoCurrency
        }
        
        if let cardNumber = order.cardNumber {
            result.cardNumber = cardNumber
        }
        
        if let cardExpiryDate = order.cardExpiryDate {
            result.cardExpiryDate = cardExpiryDate
        }
        
        if let cardCVV = order.cardCVV {
            result.cardCVV = cardCVV
        }
        
        if let walletAddress = order.walletAddress {
            result.walletAddress = walletAddress
        }
        
        if let walletTag = order.walletTag {
            result.walletTag = walletTag
        }
        
        if let email = order.email, DataValidator.isValid(email: email) {
            result.email = email
        }
        
        if let country = order.country {
            result.country = country
        }
        
        if let state = order.state {
            result.state = state
        }
        
        if let ssn = order.ssn {
            result.ssn = ssn
        }
        
        if let isIdentityDocumentsRequired = order.isIdentityDocumentsRequired {
            result.isIdentityDocumentsRequired = isIdentityDocumentsRequired
        }
        
        if let isSelfieRequired = order.isSelfieRequired {
            result.isSelfieRequired = isSelfieRequired
        }
        
        if let additionalInfo = order.additionalInfo {
            result.additionalInfo = additionalInfo
        }
        
        if let paymentConfirmationTxID = order.paymentConfirmationTxID {
            result.paymentConfirmationTxID = paymentConfirmationTxID
        }
        
        if let paymentConfirmationURL = order.paymentConfirmationURL {
            result.paymentConfirmationURL = paymentConfirmationURL
        }
        
        if let paymentConfirmationBody = order.paymentConfirmationBody {
            result.paymentConfirmationBody = paymentConfirmationBody
        }
        
        if let txID = order.txID {
            result.txID = txID
        }
        
        return result
    }
    
    func reset() -> Order {
        var result = self
        result.orderID = nil
        result.merchantOrderID = nil
        
        result.state = nil
        result.ssn = nil
        
        result.isIdentityDocumentsRequired = nil
        result.isSelfieRequired = nil
        
        result.additionalInfo = nil
        
        result.paymentConfirmationTxID = nil
        result.paymentConfirmationURL = nil
        result.paymentConfirmationBody = nil
        
        result.txID = nil
        
        return result
    }
}
