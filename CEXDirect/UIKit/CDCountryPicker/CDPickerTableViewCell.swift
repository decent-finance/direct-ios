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
//  Created by Alex Kovalenko on 9/5/18 11:37.

import UIKit

enum CDPickerEnum: String {
    case name = "name"
    case code = "code"
}

class CDPickerTableViewCell: UITableViewCell {

    @IBOutlet weak var countryImageView: UIImageView!
    @IBOutlet weak var imageViewSection: UIView!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var currencyCodeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    static func reuseIdentifier() -> String {
        return "countryCellIdentifier"
    }
    
    static func classNameAsString() -> String {
        return String(describing: CDPickerTableViewCell.self)
    }
    
    func configCell(dict: Dictionary<String, String>, selectedCode: String, isCountryStateCell: Bool) {
        
        currencyCodeLabel.isHidden = true
        imageViewSection.isHidden = isCountryStateCell
        
        if let countryCode = dict[CDPickerEnum.code.rawValue] {
            let codeString = countryCode
            
            let imagePath = "\("CountryPicker.bundle")/\(codeString)"
            var image = UIImage()
            
            if let countryImage = UIImage.init(named: imagePath, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                image = countryImage
            } else if let countryImage = UIImage.init(named: imagePath) {
                image = countryImage
            }
            
            countryImageView.image = image
        }
        
        if let countryName = dict[CDPickerEnum.name.rawValue] {
            nameLabel.text = countryName
            checkmarkImageView.isHidden = countryName != selectedCode
        } else {
            nameLabel.text = ""
        }
    }

    func configCurrencyCell(dict : Dictionary<String, String>, selectedCode: String) {
        
        imageViewSection.isHidden = true
        nameLabel.text = dict[CDPickerEnum.name.rawValue] ?? ""
        
        if let currencyName = dict[CDPickerEnum.code.rawValue] {
            currencyCodeLabel.text = currencyName.uppercased()
            checkmarkImageView.isHidden = currencyName != selectedCode
        } else {
            currencyCodeLabel.text = ""
        }
    }
}
