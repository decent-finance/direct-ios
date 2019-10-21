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
//  Created by Alex Kovalenko on 5/28/19.

import UIKit

protocol QRScannerViewControllerDelegate: class {
    func scanningSuccessWithCode(qrCode: String)
}

class QRScannerViewController: UIViewController {
    
    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            scannerView.delegate = self
        }
    }
    
    weak var delegate: QRScannerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }
    
    @IBAction func cancelButtonHandler(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension QRScannerViewController: QRScannerViewDelegate {
    
    func qrScanningDidStop() {

    }
    
    func qrScanningDidFail() {
        cd_presentInfoAlert(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Scanning Failed. Please try again", comment: "")) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func qrScanningSucceededWithCode(_ str: String) {
        delegate?.scanningSuccessWithCode(qrCode: str)
        self.dismiss(animated: true, completion: nil)
    }
}
