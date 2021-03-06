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
//  Created by Ihor Vovk on 4/1/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

protocol MainViewControllerDelegate: class {
    
    func setUpFooterViewController(_ controller: FooterViewController)
    func setUpFillBaseInfoViewController(delegate: FillBaseInfoViewControllerDelegate) -> FillBaseInfoViewController
    func setUpFillPaymentInfoContainerViewController(baseInfoDelegate: FillBaseInfoViewControllerDelegate, paymentInfoDelegate: FillPaymentInfoViewControllerDelegate) -> FillInfoContainerViewController
    func setUpFillAdditionalInfoContainerViewController(baseInfoDelegate: FillBaseInfoViewControllerDelegate, paymentInfoDelegate: FillPaymentInfoViewControllerDelegate, additionalInfoDelegate: FillAdditionalInfoViewControllerDelegate) -> FillInfoContainerViewController
    func setUpConfirmPaymentViewController(delegate: ConfirmPaymentViewControllerDelegate) -> ConfirmPaymentViewController
    func setUpConfirmEmailViewController(delegate: ConfirmEmailViewControllerDelegate) -> ConfirmEmailViewController
    func setUpPurchaseSuccessViewController(delegate: PurchaseSuccessViewControllerDelegate) -> PurchaseSuccessViewController
    func setUpGeneralErrorViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController
    func setUpServiceDownViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController
    func setUpVerificationRejectedViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController
    func setUpProcessingRejectedViewControler(delegate: BaseErrorViewControllerDelegate) -> BaseErrorViewController
    func setUpVerificationViewControler() -> VerificationViewController
    func setUpPaymentRefundedViewController(delegate: BaseErrorViewControllerDelegate) -> PaymentRefundedViewController
    func setUpLocationUnsupportedViewController(delegate: LocationUnsupportedViewControllerDelegate) -> LocationUnsupportedViewController
    func editTapped(_ mainViewController: MainViewController)
    func сonfirmEmailViewControllerDidTapEditEmail(_ controller: ConfirmEmailViewController, mainViewController: MainViewController)
    func didTapRule(mainViewController: MainViewController, didTapRule rule: String)
    func didTapBuyMoreCrypto(_ mainViewController: MainViewController)
}

class MainViewController: UIViewController, StoryboardView, FillBaseInfoViewControllerDelegate, FillPaymentInfoViewControllerDelegate, FillAdditionalInfoViewControllerDelegate, ConfirmPaymentViewControllerDelegate, ConfirmEmailViewControllerDelegate, EditEmailViewControllerDelegate, PurchaseSuccessViewControllerDelegate {
    
    weak var delegate: MainViewControllerDelegate?
    var context: AnyObject?
    
    var disposeBag = DisposeBag()
    
    var nextEnabled: RxCocoa.Binder<Bool> {
        return nextButton.rx.isEnabled
    }
    
    var nextTap: ControlEvent<Void> {
        return nextButton.rx.tap
    }

    let submitionFinishedSubject = PublishSubject<Void>()
    let locationNotSupportedSubject = BehaviorSubject<Bool>(value: false)
    let serviceDownErrorSubject = BehaviorSubject<Bool>(value: false)
    let loadingSubject = BehaviorSubject<Bool>(value: false)
    
    func scrollToErrorField(field: UIView) {
        scrollView.layoutIfNeeded()
        
        var fieldRect = field.convert(field.bounds, to: self.scrollView)
        let buttonRect = nextButton.convert(nextButton.bounds, to: self.scrollView)
        let correctRect = fieldRect.origin.y + buttonRect.height
        if  correctRect >= buttonRect.origin.y {
            fieldRect.origin.y = correctRect
        } else {
            fieldRect.origin.y -= 20
        }
        
        scrollView.scrollRectToVisible(fieldRect, animated: true)
    }
    
    func didTapRule(didTapRule rule: String) {
        delegate?.didTapRule(mainViewController: self, didTapRule: rule)
    }
    
    func showServiceDownError() {
        showInfo(content: .serviceDown)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logo = UIImage(named: "logo", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let imageView = UIImageView(image: logo)
        navigationItem.titleView = imageView
        
        setUpFooterView()
        hideKeyboardWhenTappedAround()
        orderIdLabel.addGestureRecognizer(tapGesture)
    }
    
    func bind(reactor: MainViewReactor) {
        reactor.state.map { String(format: NSLocalizedString("Purchase %@ for %@", comment: ""), $0.cryptoCurrency ?? "", $0.fiatCurrency ?? "") }
            .bind(to: purchaseLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map {_ in reactor.purchaseInfoTitle() }
            .bind(to: buyLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state.map { String(format: NSLocalizedString("Order id: %@", comment: ""), $0.orderId ?? "") }
            .bind(to: orderIdLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state.map { $0.orderId == nil }
            .bind(to: orderIdLabel.rx.isHidden )
            .disposed(by: disposeBag)
        
        Observable.combineLatest(reactor.state.map { $0.infoContent }, locationNotSupportedSubject, serviceDownErrorSubject).map { (infoContent, isLocationNotSupported, isServiceDown) -> Reactor.InfoContent? in
            if isServiceDown {
                return .serviceDown
            } else if isLocationNotSupported {
                return .locationNotSupported
            } else {
                return infoContent
            }
        }.subscribe(onNext: { [unowned self] infoContent in
            if let infoContent = infoContent {
                self.loadingView.isHidden = true
                self.showInfo(content: infoContent)
                if infoContent == .locationNotSupported {
                    self.buyLabel.isHidden = true
                    self.logoImageLeftConstraint?.isActive = false
                }
            } else {
                self.hideInfo()
                self.buyLabel.isHidden = false
                self.logoImageLeftConstraint?.isActive = true
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.pageContent }.distinctUntilChanged().subscribe(onNext: { [unowned self] pageContent in
            switch pageContent {
            case .baseFillInformation:
                if let contentVC = self.delegate?.setUpFillBaseInfoViewController(delegate: self) {
                    self.showPageContentViewController(contentVC)
                }
            case .paymentFillInformation:
                if let contentVC = self.delegate?.setUpFillPaymentInfoContainerViewController(baseInfoDelegate: self, paymentInfoDelegate: self) {
                    self.showPageContentViewController(contentVC)
                }
            case .additionalFillInformation:
                if let contentVC = self.delegate?.setUpFillAdditionalInfoContainerViewController(baseInfoDelegate: self, paymentInfoDelegate: self, additionalInfoDelegate: self) {
                    self.showPageContentViewController(contentVC)
                }
                self.nextButton.title = NSLocalizedString("VERIFY", comment: "")
                self.shouldHideEditButton = true
            case .paymentConfirmation:
                self.nextButton.isHidden = true
                if let contentVC = self.delegate?.setUpConfirmPaymentViewController(delegate: self) {
                    self.showPageContentViewController(contentVC)
                }
                self.shouldHideEditButton = true
            case .emailConfirmation:
                self.nextButton.isHidden = false
                self.nextButton.title = NSLocalizedString("SUBMIT", comment: "")
                if let contentVC = self.delegate?.setUpConfirmEmailViewController(delegate: self) {
                    self.showPageContentViewController(contentVC)
                    self.nextButtonBottomConstraint.constant = contentVC.submitButtonBottomOffset
                }
            case .purchaseSuccess:
                self.nextButton.isHidden = false
                self.nextButton.title = NSLocalizedString("BUY MORE CRYPTO", comment: "")
                self.nextButtonBottomConstraint.constant = 0
                if let contentVC = self.delegate?.setUpPurchaseSuccessViewController(delegate: self) {
                    self.showPageContentViewController(contentVC)
                }
            }
        }).disposed(by: disposeBag)
        
        pageTitleCollectionView.rx.didScroll.compactMap { [weak self] in self?.pageTitleCollectionView }
            .map { $0.indexPathForItem(at: $0.convert($0.center, from: $0.superview))?.item ?? 0 }
            .skip(2)
            .subscribe(onNext: { [weak self] index in
                self?.pageControl.currentPage = index
            }).disposed(by: disposeBag)
        
        tapGesture.rx.event.bind(onNext: { [unowned self] recognizer in
            if let orderID = reactor.currentState.orderId, orderID.count > 0 {
                UIPasteboard.general.string = orderID
                self.cd_presentInfoAlert(message: NSLocalizedString("Order ID has been copied to clipboard!", comment: ""), completion: nil)
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.page }.distinctUntilChanged().delay(.milliseconds(100), scheduler: MainScheduler.instance).subscribe(onNext: { [unowned self] page in
            self.pageControl.currentPage = page.rawValue
            self.pageControl.shownPage = page.rawValue
            self.pageTitleCollectionView.scrollToItem(at: IndexPath(row: page.rawValue, section: 0), at: [.centeredHorizontally], animated: false)
        }).disposed(by: disposeBag)
        
        submitionFinishedSubject.flatMap { [unowned self] () -> Observable<Reactor.Action> in
            guard let currentPageContentViewController = self.currentPageContentViewController else { return Observable.empty() }
            
            if currentPageContentViewController.isKind(of: FillBaseInfoViewController.self)  {
                return Observable.just(Reactor.Action.finish(.baseFillInformation))
            } else if let containerController = currentPageContentViewController as? FillInfoContainerViewController, containerController.mainViewController.isKind(of: FillPaymentInfoViewController.self)  {
                return Observable.just(Reactor.Action.finish(.paymentFillInformation))
            } else if let containerController = currentPageContentViewController as? FillInfoContainerViewController, containerController.mainViewController.isKind(of: FillAdditionalInfoViewController.self)  {
                return Observable.just(Reactor.Action.finish(.additionalFillInformation))
            } else if currentPageContentViewController.isKind(of: ConfirmPaymentViewController.self) {
                return Observable.just(Reactor.Action.finish(.paymentConfirmation))
            } else if currentPageContentViewController.isKind(of: ConfirmEmailViewController.self) {
                return Observable.just(Reactor.Action.finish(.emailConfirmation))
            } else if currentPageContentViewController.isKind(of: PurchaseSuccessViewController.self) {
                self.delegate?.didTapBuyMoreCrypto(self)
                return Observable.just(Reactor.Action.finish(.purchaseSuccess))
            } else {
                return Observable.empty()
            }
        }.bind(to: reactor.action).disposed(by: disposeBag)
        
        Observable.combineLatest(reactor.state.map { $0.isLoading }, loadingSubject).map { (isLoading, loadingSubject) -> Bool in
            return isLoading == false && loadingSubject == false
        }.map { $0 }
            .bind(to: loadingView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setUpFooterView() {
        let footerController = FooterViewController.init(nibName: String(describing: FooterViewController.self), bundle: Bundle(for: type(of: self)))
        delegate?.setUpFooterViewController(footerController)
        cd_addChildViewController(footerController, containerView: footerView)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var nextButton: CDButton!
    @IBOutlet private weak var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var pageTitleCollectionView: UICollectionView!
    @IBOutlet private weak var pageControl: CDPageControl!
    @IBOutlet private weak var pageContentContainerView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var purchaseLabel: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var infoView: UIView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var loadingView: CDLoadingView!
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var buyLabel: UILabel!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private var logoImageLeftConstraint: NSLayoutConstraint!
    
    private var currentPageContentViewController: UIViewController?
    private let tapGesture = UITapGestureRecognizer()
    private var shouldHideEditButton = false {
        didSet {
            pageTitleCollectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        }
    }
    
    private func showInfo(content: MainViewReactor.InfoContent) {
        hideInfo()
        
        var infoViewController: UIViewController?
        
        switch content {
        case .generalError:
            infoViewController = delegate?.setUpGeneralErrorViewControler(delegate: self)
        case .serviceDown:
            infoViewController = delegate?.setUpServiceDownViewControler(delegate: self)
        case .verificationRejected:
            infoViewController = delegate?.setUpVerificationRejectedViewControler(delegate: self)
        case .processingRejected:
            infoViewController = delegate?.setUpProcessingRejectedViewControler(delegate: self)
        case .locationNotSupported:
            infoViewController = delegate?.setUpLocationUnsupportedViewController(delegate: self)
        case .verificationInProgress:
            infoViewController = delegate?.setUpVerificationViewControler()
        case .paymentRefunded:
            infoViewController = delegate?.setUpPaymentRefundedViewController(delegate: self)
        }
        
        if let infoViewController = infoViewController {
            cd_addChildViewController(infoViewController, containerView: infoView)
            
            contentView.isHidden = true
            infoView.isHidden = false
            nextButton.isHidden = true
            
            scrollView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    
    private func hideInfo() {
        for viewController in children.filter({ $0 is BaseErrorViewController || $0 is VerificationViewController }) {
            self.cd_removeChildViewController(viewController)
        }
        
        contentView.isHidden = false
        infoView.isHidden = true
        nextButton.isHidden = false
    }
    
    private func showPageContentViewController(_ contentViewController: UIViewController) {
        currentPageContentViewController?.willMove(toParent: nil)
        addChild(contentViewController)
        if let currentPageContentViewController = currentPageContentViewController {
            transition(from: currentPageContentViewController, to: contentViewController, duration: 0.1, options: UIView.AnimationOptions.transitionCrossDissolve, animations: nil) { (Bool) -> Void in
                currentPageContentViewController.view.removeFromSuperview()
                currentPageContentViewController.removeFromParent()
                contentViewController.didMove(toParent: self)
            }
        } else {
            pageContentContainerView.addSubview(contentViewController.view)
            contentViewController.didMove(toParent: self)
        }
        
        if let contentView = contentViewController.view {
            contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
            pageContentContainerView.addConstraints([
                NSLayoutConstraint(item: contentView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: contentView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: contentView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: contentView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
            ])
        }
        
        scrollView.setContentOffset(CGPoint.zero, animated: false)
        currentPageContentViewController = contentViewController
    }
}

extension MainViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Reactor.Page.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let result = collectionView.dequeueReusableCell(withReuseIdentifier: "pageTitleCell", for: indexPath) as! PurchasePageTitleCell
        if let page = Reactor.Page(rawValue: indexPath.item) {
            result.titleLabel.text = reactor?.title(page: page)
        }
        
        if indexPath.row == 0 {
            result.editButton.isHidden = shouldHideEditButton
            result.editButton.rx.tap
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.delegate?.editTapped(self)
                })
                .disposed(by: result.disposeBag)
        }
        
        return result
    }
}

extension MainViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewSize = collectionView.frame.size
        let cellWidth = collectionViewSize.width - Constant.PageTitle.IndentSize * 2
        return CGSize(width: cellWidth, height: collectionViewSize.height)
    }
}

extension MainViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? UICollectionView else { return }
        
        if let currentPageIndexPath = collectionView.indexPathForItem(at: collectionView.convert(collectionView.center, from: collectionView.superview)) {
            collectionView.scrollToItem(at: currentPageIndexPath, at: .centeredHorizontally, animated: true)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let collectionView = scrollView as? UICollectionView else { return }

        if let currentPageIndexPath = collectionView.indexPathForItem(at: collectionView.convert(collectionView.center, from: collectionView.superview)) {
            collectionView.scrollToItem(at: currentPageIndexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

extension MainViewController {
    
    func сonfirmEmailViewControllerDidTapEditEmail(_ controller: ConfirmEmailViewController) {
        delegate?.сonfirmEmailViewControllerDidTapEditEmail(controller, mainViewController: self)
    }
}

extension MainViewController: BaseErrorViewControllerDelegate {
    
    func errorViewControllerDidTapButton(_ controller: BaseErrorViewController) {
        controller.removeFromParent()
        delegate?.editTapped(self)
    }
}

extension MainViewController: LocationUnsupportedViewControllerDelegate {
    
    func locationUnsupportedViewControlleDidTapBack(_ controller: LocationUnsupportedViewController) {
        locationNotSupportedSubject.onNext(false)
    }
}
