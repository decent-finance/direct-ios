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
    func setUpErrorInformationViewControler(delegate: ErrorInfoViewControllerDelegate) -> ErrorInfoViewController
    func setUpLocationNotSupportedViewController() -> LocationUnsupportedViewController
    func editTapped(_ mainViewController: MainViewController)
    func сonfirmEmailViewControllerDidTapEditEmail(_ controller: ConfirmEmailViewController, mainViewController: MainViewController)
    func didTapRule(mainViewController: MainViewController, didTapRule rule: String)
    func didTapBuyMoreCrypto(_ mainViewController: MainViewController)
}

class MainViewController: UIViewController, StoryboardView, FillBaseInfoViewControllerDelegate, FillPaymentInfoViewControllerDelegate, FillAdditionalInfoViewControllerDelegate, ConfirmPaymentViewControllerDelegate, ConfirmEmailViewControllerDelegate, EditEmailViewControllerDelegate, PurchaseSuccessViewControllerDelegate {

    var delegate: MainViewControllerDelegate?
    var disposeBag = DisposeBag()
    
    var nextEnabled: RxCocoa.Binder<Bool> {
        return nextButton.rx.isEnabled
    }
    
    var nextTap: ControlEvent<Void> {
        return nextButton.rx.tap
    }

    let submitionFinishedSubject = PublishSubject<Void>()
    let locationNotSupportedSubject = BehaviorSubject<Bool>(value: false)
    let loadingSubject = BehaviorSubject<Bool>(value: false)
    
    func scrollToErrorField(field: UIView) {
        self.scrollView.layoutIfNeeded()
        var fieldRect = field.convert(field.bounds, to: self.scrollView)
        let buttonRect = nextButton.convert(nextButton.bounds, to: self.scrollView)
        let correctRect = fieldRect.origin.y + buttonRect.height
        if  correctRect >= buttonRect.origin.y {
            fieldRect.origin.y = correctRect
        } else {
            fieldRect.origin.y -= 20
        }
        self.scrollView.scrollRectToVisible(fieldRect, animated: true)
    }
    
    func didTapRule(didTapRule rule: String) {
        delegate?.didTapRule(mainViewController: self, didTapRule: rule)
    }
    
    func showErrorViewWithReason(errorReason: String?) {
        self.showErrorInfoViewWithReason(reason: errorReason)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logo = UIImage(named: "logo", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let imageView = UIImageView(image: logo)
        navigationItem.titleView = imageView
        
        setUpFooterView()
        self.hideKeyboardWhenTappedAround()
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
        
        reactor.state.map {$0.errorReason }.filter { $0 != nil }.subscribe(onNext: { [unowned self] errorReason in
            self.showErrorInfoViewWithReason(reason: errorReason)
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
        
        pageTitleCollectionView.rx.didScroll.map { [unowned self] in self.pageTitleCollectionView }
            .map { $0.indexPathForItem(at: $0.convert($0.center, from: $0.superview))?.item ?? 0 }
            .skip(2)
            .subscribe(onNext: { [unowned self] index in
                self.pageControl.currentPage = index
            }).disposed(by: disposeBag)
        
        tapGesture.rx.event.bind(onNext: { [unowned self] recognizer in
            if let orderID = reactor.currentState.orderId, orderID.count > 0 {
                UIPasteboard.general.string = orderID
                self.cd_presentInfoAlert(message: NSLocalizedString("Order ID has been copied to clipboard!", comment: ""), completion: nil)
            }
        }).disposed(by: disposeBag)
        
        reactor.state.map { $0.page }.distinctUntilChanged().delay(0.1, scheduler: MainScheduler.instance).subscribe(onNext: { [unowned self] page in
            self.pageControl.currentPage = page.rawValue
            self.pageControl.shownPage = page.rawValue
            self.pageTitleCollectionView.scrollToItem(at: IndexPath(row: page.rawValue, section: 0), at: [.centeredHorizontally], animated: false)
        }).disposed(by: disposeBag)
        
        submitionFinishedSubject.flatMap { () -> Observable<Reactor.Action> in
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
        
        locationNotSupportedSubject.filter { $0 }.subscribe(onNext: { [unowned self] errorReason in
            if let contentVC = self.delegate?.setUpLocationNotSupportedViewController() {
                self.cd_addChildViewController(contentVC, containerView: self.errorInfoView)
                
                self.buyLabel.isHidden = true
                self.contentView.isHidden = true
                self.errorInfoView.isHidden = false
                self.nextButton.isHidden = true
                if let logoImageLeftConstraint = self.logoImageLeftConstraint {
                    logoImageLeftConstraint.isActive = false
                }
            }
        }).disposed(by: disposeBag)
        
        Observable.merge(reactor.state.map { $0.isLoading }, loadingSubject).flatMapLatest { isLoading -> Observable<Bool> in
            return isLoading ? Observable.just(isLoading).delay(0.2, scheduler: MainScheduler.instance) : .just(isLoading)
        }.map { !$0 }
            .bind(to: loadingView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setUpFooterView() {
        let footerController = FooterViewController.init(nibName: String(describing: FooterViewController.self), bundle: Bundle(for: type(of: self)))
        self.cd_addChildViewController(footerController, containerView: footerView)
        delegate?.setUpFooterViewController(footerController)
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
    @IBOutlet private weak var errorInfoView: UIView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var loadingView: CDLoadingView!
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var buyLabel: UILabel!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var logoImageLeftConstraint: NSLayoutConstraint!
    
    private var currentPageContentViewController: UIViewController?
    private let tapGesture = UITapGestureRecognizer()
    private var shouldHideEditButton = false {
        didSet {
            self.pageTitleCollectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        }
    }
    
    private func showErrorInfoViewWithReason(reason text: String?) {
        let errorInfoViewControllerArray = self.children.filter({$0 is ErrorInfoViewController})
        if let errorInfoViewController = errorInfoViewControllerArray.first {
            self.cd_removeChildViewController(errorInfoViewController)
        }
        
        if let contentVC = self.delegate?.setUpErrorInformationViewControler(delegate: self) {
            contentVC.reasonErrorText = text
            self.cd_addChildViewController(contentVC, containerView: self.errorInfoView)
            
            self.contentView.isHidden = true
            self.errorInfoView.isHidden = false
            self.nextButton.isHidden = true
            
            self.scrollView.setContentOffset(CGPoint.zero, animated: false)
        }
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
        
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageContentContainerView.addConstraints([
            NSLayoutConstraint(item: contentViewController.view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: contentViewController.view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: contentViewController.view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: contentViewController.view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pageContentContainerView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
        ])
        
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

extension MainViewController: ErrorInfoViewControllerDelegate {
    
    func errorInformationViewControllerDidTapButton(_ controller: ErrorInfoViewController) {
        controller.removeFromParent()
        self.delegate?.editTapped(self)
    }
}
