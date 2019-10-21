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

class DocumentTypeCell: UITableViewCell {
    
    @IBOutlet weak var idCardButton: UIButton!
    @IBOutlet weak var driverLicenseButton: UIButton!
    @IBOutlet weak var passportButton: UIButton!
    @IBOutlet weak var docImageView: UIImageView!
    @IBOutlet weak var paymentCardImageView: UIImageView!
    @IBOutlet weak var uploadDocButton: UIButton!
    @IBOutlet weak var uploadPaymentCardButton: UIButton!
    
    class var identifier: String {
        return "DocumentTypeCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
