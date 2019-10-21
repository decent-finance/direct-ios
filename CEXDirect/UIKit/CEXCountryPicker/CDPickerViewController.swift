//
//  PickerViewController.swift
//  SuperScheet
//
//  Created by Alex Kovalenko on 8/30/18.
//  Copyright © 2018 Alex Kovalenko. All rights reserved.
//

import UIKit

protocol CDPickerDelegate: class {
    func selectedPickerValue(dict: Dictionary<String, String>)
    func selectedCurrencyValue(textField: CDAmountTextField?, dict: Dictionary<String, String>)
}

extension CDPickerDelegate {
    func selectedCurrencyValue(textField: CDAmountTextField?, dict: Dictionary<String, String>) {
        /* return a default value or just leave empty */
    }
}

class CDPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate/*, CDTextFieldDelegate*/ {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var chooseCountryView: UIView!
    @IBOutlet weak var searchTextField: CDTextField!
    @IBOutlet weak var chooseCountryLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var cancelButton: CDButton!
    
    weak var delegate: CDPickerDelegate?
    
    var cdPickerArray = [Dictionary<String, String>]()
    var searchResults = [Dictionary<String, String>]()
    
    var selectedCurrencyTextField: CDAmountTextField?
    
    var resultPredicate : NSPredicate?
    var selectedCode : String?
    var isCountryPicker = true
    
    private var keyboardHeight:CGFloat = 0
    private var defaultTableViewHeight:CGFloat = 402
    
    var defaultOffSet: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        defaultTableViewHeight = tableView.frame.size.height
        
        tableView.register(UINib(nibName: CDPickerTableViewCell.classNameAsString(), bundle: Bundle(for: type(of: self))), forCellReuseIdentifier: CDPickerTableViewCell.reuseIdentifier())
        
//        searchTextField.delegate = self
        
        if isCountryPicker {
            chooseCountryLabel.text = "Choose Country"
            
            cdPickerArray = CountryListDataSource.shared.countries()
        } else {
            searchButton.isHidden = true
            chooseCountryLabel.text = "Choose Cryptocurrency"
        }

        filter()
        configView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: cancelButton.frame.height + 10))
        tableView.tableFooterView = customView
        
        if !isCountryPicker {
            tableViewHeight.constant = tableView.contentSize.height
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        defaultOffSet = tableView.contentOffset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if !isCountryPicker {
            return
        }
        
        let offset = tableView.contentOffset
        
        if let startOffset = self.defaultOffSet {
            if offset.y < startOffset.y {
                // Scrolling down
                // check if your collection view height is less than normal height, do your logic.
                
                if keyboardHeight > 0 {
                    return
                }
                
                if tableViewHeight.constant <= defaultTableViewHeight {
                    tableViewHeight.constant = defaultTableViewHeight
                    return
                }
                
                let deltaY = Swift.abs((startOffset.y - offset.y))
                tableViewHeight.constant = tableViewHeight.constant - deltaY
                
            } else {
                // Scrolling up
                
                if tableViewHeight.constant >= maxTableViewHeight() - keyboardHeight {
                    tableViewHeight.constant = maxTableViewHeight() - keyboardHeight
                    return
                }
                
                let deltaY = Swift.abs((startOffset.y - offset.y))
                tableViewHeight.constant = tableViewHeight.constant + deltaY
                
                tableView.contentOffset = CGPoint(x: 0, y: 0)
            }
            
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        keyboardHeight = keyboardFrameValue.cgRectValue.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        keyboardHeight = 0
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Button Handler
    
    @IBAction func searchButtonHandler(_ sender: Any) {
        chooseCountryView.isHidden = true

        let _ = searchTextField.becomeFirstResponder()
        tableViewHeight.constant = maxTableViewHeight() - keyboardHeight
    }
    
    @IBAction func cancelSearchButtonHandler(_ sender: Any) {
        chooseCountryView.isHidden = false
        
        searchTextField.text = ""
        resultPredicate = nil
        filter()
        
        let _ = searchTextField.resignFirstResponder()
    }
    
    @IBAction func cancelButtonHandler(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CDPickerTableViewCell.reuseIdentifier()) as! CDPickerTableViewCell
        if isCountryPicker {
            cell.configCell(dict: searchResults[indexPath.row], selectedCode: selectedCode ?? "")
        } else {
            cell.configCurrencyCell(dict: searchResults[indexPath.row], selectedCode: selectedCode ?? "")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        delegate?.selectedPickerValue(dict: searchResults[indexPath.row])
        delegate?.selectedCurrencyValue(textField: selectedCurrencyTextField, dict: searchResults[indexPath.row])
        
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - CEXTextFieldDelegate Method
    
    func textFieldDidChange(_ textField: CDTextField) {
        guard let text = textField.text else {
            return
        }
        resultPredicate = text.count > 0 ? NSPredicate(format: "name contains[c] %@", text) : nil
        filter()
    }
    
    // MARK: - Filter
    
    func filter() {
        searchResults = cdPickerArray
        
        if let predicate = resultPredicate {
            searchResults = cdPickerArray.filter{predicate.evaluate(with: ($0))}
        }

        searchResults = searchResults.sorted{$0["name"]! < $1["name"]!}
        self.tableView.reloadData()
    }

    // MARK: - Utility
    
    private func maxTableViewHeight() -> CGFloat {
        var topInset:CGFloat = 0
        
        if let rootView = UIApplication.shared.keyWindow {
            if #available(iOS 11.0, *) {
                topInset = rootView.safeAreaInsets.top
                
                if topInset == 0 {
                    topInset = UIApplication.shared.statusBarFrame.size.height
                }
            }
        }
        
        return UIScreen.main.bounds.size.height - titleView.frame.height - topInset - 44
    }
    
    // MARK: - Config
    
    private func configView() {
//        self.view.backgroundColor = ThemeManager.cex_gray20
//        titleView.backgroundColor = ThemeManager.cex_gray20
//        tableView.backgroundColor = ThemeManager.cex_gray20
//        chooseCountryView.backgroundColor = ThemeManager.cex_gray20
//        chooseCountryLabel.textColor = ThemeManager.cex_white
    }
}
