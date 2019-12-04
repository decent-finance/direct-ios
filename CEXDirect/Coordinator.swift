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

class Coordinator {
    
    let serviceProvider: ServiceProvider
    let orderStore: OrderStore
    let rulesStore: RulesStore
    let countriesStore: CountriesStore
    
    init(serviceProvider: ServiceProvider, order: Order) {
        self.serviceProvider = serviceProvider
        orderStore = OrderStore(order: order)
        rulesStore = RulesStore()
        countriesStore = CountriesStore()
    }
    
    lazy var rootViewController: UIViewController? = {
        let result = UIStoryboard(name: "OrderAmount", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? OrderAmountViewController
        result?.reactor = OrderAmountViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
        result?.delegate = self
        result?.context = self
        
        return result
    }()
    
    func setUpFooterViewController(_ controller: FooterViewController) {
        controller.reactor = FooterViewReactor(ruleStore: rulesStore)
        controller.isExitHidden = (rootViewController?.presentingViewController == nil)
        controller.delegate = self
    }
}

extension Coordinator: OrderAmountViewControllerDelegate {
    
    func setUpVerifyPlacementViewController(_ controller: VerifyPlacementViewController, delegate: VerifyPlacementViewControllerDelegate) {
        controller.reactor = VerifyPlacementViewReactor(serviceProvider: serviceProvider, rulesStore: rulesStore, countriesStore: countriesStore)
        controller.delegate = delegate
    }
    
    func orderAmountViewControllerDidTapBuy(_ controller: OrderAmountViewController) {
        if let mainViewController = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? MainViewController {
            mainViewController.reactor = MainViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
            mainViewController.delegate = self
            
            controller.present(mainViewController, animated: true, completion: nil)
        }
    }
    
    func orderAmountViewControllerDidTapExit(_ controller: OrderAmountViewController) {
        rootViewController?.presentingViewController?.dismiss(animated: true)
    }
}

extension Coordinator: MainViewControllerDelegate {
    func didTapBuyMoreCrypto(_ mainViewController: MainViewController) {
        orderStore.reset()
        rootViewController?.dismiss(animated: true)
    }
    
    func didTapRule(mainViewController: MainViewController, didTapRule rule: String) {
        let ruleViewController = RuleViewController.cd_instantiateFromStoryboard()
        ruleViewController.reactor = RuleViewReactor(rule: rule)
        mainViewController.present(ruleViewController, animated: true, completion: nil)
    }
    
    func setUpFillBaseInfoViewController(delegate: FillBaseInfoViewControllerDelegate) -> FillBaseInfoViewController {
        return setUpFillBaseInfoViewController(delegate: delegate, isEditing: false)
    }
    
    func setUpFillPaymentInfoContainerViewController(baseInfoDelegate: FillBaseInfoViewControllerDelegate, paymentInfoDelegate: FillPaymentInfoViewControllerDelegate) -> FillInfoContainerViewController {
        let fillBaseInfoViewController = setUpFillBaseInfoViewController(delegate: baseInfoDelegate, isEditing: true)
        let fillPaymentInfoViewController = setUpFillPaymentInfoViewController(delegate: paymentInfoDelegate, isEditing: false)
        
        let result = FillInfoContainerViewController.cd_instantiateFromStoryboard()
        result.setUp(mainViewController: fillPaymentInfoViewController, sectionViewControllers: [(NSLocalizedString("Email and Country", comment: ""), fillBaseInfoViewController)])
        
        return result
    }
    
    func setUpFillAdditionalInfoContainerViewController(baseInfoDelegate: FillBaseInfoViewControllerDelegate, paymentInfoDelegate: FillPaymentInfoViewControllerDelegate, additionalInfoDelegate: FillAdditionalInfoViewControllerDelegate) -> FillInfoContainerViewController {
        let fillBaseInfoViewController = setUpFillBaseInfoViewController(delegate: baseInfoDelegate, isEditing: true)
        let fillPaymentInfoViewController = setUpFillPaymentInfoViewController(delegate: paymentInfoDelegate, isEditing: true)
       
        let fillAdditionalInfoViewController = FillAdditionalInfoViewController.cd_instantiateFromStoryboard()
        fillAdditionalInfoViewController.reactor = FillAdditionalInfoViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
        fillAdditionalInfoViewController.delegate = additionalInfoDelegate
        
        let result = FillInfoContainerViewController.cd_instantiateFromStoryboard()
        result.setUp(mainViewController: fillAdditionalInfoViewController, sectionViewControllers: [(NSLocalizedString("Email and Country", comment: ""), fillBaseInfoViewController), (NSLocalizedString("Identity and Payment Data", comment: ""), fillPaymentInfoViewController)])
        
        return result
    }
    
    func setUpConfirmPaymentViewController(delegate: ConfirmPaymentViewControllerDelegate) -> ConfirmPaymentViewController {
        let result = ConfirmPaymentViewController.cd_instantiateFromStoryboard()
        result.reactor = ConfirmPaymentViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
        result.delegate = delegate
        
        return result
    }
    
    func setUpConfirmEmailViewController(delegate: ConfirmEmailViewControllerDelegate) -> ConfirmEmailViewController {
        let result = ConfirmEmailViewController.cd_instantiateFromStoryboard()
        result.reactor = ConfirmEmailViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
        result.delegate = delegate
        
        return result
    }
    
    func setUpGeneralErrorViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController {
        let result = BaseErrorViewController.cd_instantiateFromStoryboard(name: "GeneralErrorViewController")
        result.delegate = delegate
        
        return result
    }
    
    func setUpServiceDownViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController {
        let result = BaseErrorViewController.cd_instantiateFromStoryboard(name: "ServiceDownViewController")
        result.delegate = delegate
        
        return result
    }
    
    func setUpVerificationRejectedViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController {
        let result = BaseErrorViewController.cd_instantiateFromStoryboard(name: "VerificationRejectedViewController")
        result.delegate = delegate
        
        return result
    }
    
    func setUpProcessingRejectedViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController {
        let result = BaseErrorViewController.cd_instantiateFromStoryboard(name: "ProcessingRejectedViewController")
        result.delegate = delegate
        
        return result
    }
    
    func setUpVerificationViewControler() -> VerificationViewController {
        return VerificationViewController.cd_instantiateFromStoryboard()
    }
    
    func setUpPaymentRefundedViewController(delegate: BaseErrorViewControllerDelegate) -> PaymentRefundedViewController {
        let result = PaymentRefundedViewController.cd_instantiateFromStoryboard()
        result.reactor = PaymentRefundedViewReactor(orderStore: orderStore)
        result.delegate = delegate
        
        return result
    }
    
    func setUpLocationUnsupportedViewController(delegate: LocationUnsupportedViewControllerDelegate) -> LocationUnsupportedViewController {
        let result = LocationUnsupportedViewController.cd_instantiateFromStoryboard()
        result.delegate = delegate
        
        return result
    }
    
    func setUpPurchaseSuccessViewController(delegate: PurchaseSuccessViewControllerDelegate) -> PurchaseSuccessViewController {
        let result = PurchaseSuccessViewController.cd_instantiateFromStoryboard()
        result.reactor = PurchaseSuccessViewReactor(orderStore: orderStore)
        result.delegate = delegate
        
        return result
    }
    
    func editTapped(_ mainViewController: MainViewController) {
        orderStore.reset()
        rootViewController?.dismiss(animated: true)
    }
    
    func сonfirmEmailViewControllerDidTapEditEmail(_ controller: ConfirmEmailViewController, mainViewController: MainViewController) {
        let editEmailViewController = EditEmailViewController.cd_instantiateFromStoryboard()
        editEmailViewController.delegate = mainViewController
        editEmailViewController.reactor = EditEmailViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
        
        let bottomSheetController = CEXBottomSheetContainerController.cd_instantiateFromStoryboard(name: "CEXBottomSheetContainer")
        bottomSheetController.setup(contentViewController: editEmailViewController)
        
        controller.present(bottomSheetController, animated: true, completion: nil)
    }
    
    // MARK: - Implementation
    
    private func setUpFillBaseInfoViewController(delegate: FillBaseInfoViewControllerDelegate, isEditing: Bool) -> FillBaseInfoViewController {
        let result = FillBaseInfoViewController.cd_instantiateFromStoryboard()
        result.reactor = FillBaseInfoViewReactor(serviceProvider: serviceProvider, orderStore: orderStore, countriesStore: countriesStore, isEditing: isEditing)
        result.delegate = delegate
        
        return result
    }
    
    private func setUpFillPaymentInfoViewController(delegate: FillPaymentInfoViewControllerDelegate, isEditing: Bool) -> FillPaymentInfoViewController {
        let result = FillPaymentInfoViewController.cd_instantiateFromStoryboard()
        result.reactor = FillPaymentInfoViewReactor(serviceProvider: serviceProvider, orderStore: orderStore, rulesStore: rulesStore, isEditing: isEditing)
        result.delegate = delegate
        
        let uploadPhotoViewController = UploadPhotoViewController()
        uploadPhotoViewController.reactor = UploadPhotoViewReactor(serviceProvider: serviceProvider, orderStore: orderStore)
        result.uploadPhotoViewController = uploadPhotoViewController
        
        return result
    }
}

extension Coordinator: FooterViewControllerDelegate {
    
    func footerViewController(_ controller: FooterViewController, didTapRule rule: String) {
        let ruleViewController = RuleViewController.cd_instantiateFromStoryboard()
        ruleViewController.reactor = RuleViewReactor(rule: rule)
        controller.present(ruleViewController, animated: true, completion: nil)
    }
    
    func footerViewControllerDidTapExit(_ controller: FooterViewController) {
        rootViewController?.presentingViewController?.dismiss(animated: true)
    }
}
