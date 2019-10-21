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
//  Created by Alex Kovalenko on 7/4/19.

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import MessageUI

protocol FooterViewControllerDelegate: class {
    func footerViewController(_ controller: FooterViewController, didTapRule rule: String)
    func footerViewControllerDidTapExit(_ controller: FooterViewController)
}

class FooterViewController: UIViewController, StoryboardView {
    
    weak var delegate: FooterViewControllerDelegate?
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentYear = Calendar.current.component(.year, from: Date())
        yearLabel.text = NSLocalizedString(String(format: "© 2013-%i CEX.IO Ltd (UK)", currentYear), comment: "")
        
        collectionView.register(UINib(nibName: FooterCollectionViewCell.classNameAsString(), bundle: Bundle(for: type(of: self))), forCellWithReuseIdentifier: FooterCollectionViewCell.reuseIdentifier())
    }
    
    func bind(reactor: FooterViewReactor) {
        reactor.state.subscribe(onNext: { [unowned self] rules in
            let height = self.collectionView.collectionViewLayout.collectionViewContentSize.height
            self.collectionViewHeight.constant = height
            self.view.layoutIfNeeded()
            self.collectionView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Implementation
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var yearLabel: UILabel!
    
    private let itemsPerRow: CGFloat = 2
    private let supportEmail = "support@cexdirect.com"
    
    @IBAction func exit(_ sender: Any) {
        if let confirmExitViewController = UIStoryboard(name: "CDBaseSheet", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CDBaseSheetController,
            let sheetContainerController = UIStoryboard(name: "CEXBottomSheetContainer", bundle: Bundle(for: type(of: self))).instantiateInitialViewController() as? CEXBottomSheetContainerController {
            confirmExitViewController.setUp(title: NSLocalizedString("Do you want to exit?", comment: ""), description: nil, actionTitle: NSLocalizedString("EXIT", comment: ""), action: { [unowned self] in
                self.delegate?.footerViewControllerDidTapExit(self)
            })
                
            sheetContainerController.setup(contentViewController: confirmExitViewController)
            present(sheetContainerController, animated: true, completion: nil)
        }
    }
    
    @IBAction func support(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([supportEmail])
            present(mail, animated: true)
        } else if let mailtoURL = URL(string: "mailto:" + supportEmail), UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL)
        }
    }
}

extension FooterViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reactor?.currentState.rules.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FooterCollectionViewCell.reuseIdentifier(), for: indexPath) as! FooterCollectionViewCell
        if let reactor = reactor {
            let rule = reactor.currentState.rules[indexPath.row]
            cell.cellButton.title = rule.name
        }

        return cell
    }
}

extension FooterViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let reactor = reactor, let rule = reactor.currentState.rules[indexPath.row].value {
            delegate?.footerViewController(self, didTapRule: rule)
        }
    }
}

extension FooterViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let flowLayout = collectionViewLayout as! CollectionViewCenteredFlowLayout
        let padding = itemsPerRow * flowLayout.itemSize.width + (itemsPerRow - 1) * flowLayout.minimumInteritemSpacing
        return UIEdgeInsets(top: 10.0, left: (collectionView.frame.width - padding) / 2, bottom: 10.0, right: (collectionView.frame.width - padding) / 2)
    }
}

extension FooterViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case .sent: break
        case .saved: break
        case .cancelled: break
        case .failed:
            cd_presentInfoAlert(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Failed to send email", comment: ""))
        default:
            break
        }
        
        controller.dismiss(animated: true)
    }
}
