//
//  BenchConfigCell.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-04.
//

import UIKit

// https://stackoverflow.com/a/45771126/16823203
extension UITextField {
    func addDoneCancelToolbar(onDone: (target: Any, action: Selector)? = nil, onCancel: (target: Any, action: Selector)? = nil) {
        let onCancel = onCancel ?? (target: self, action: #selector(cancelButtonTapped))
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))

        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: onCancel.target, action: onCancel.action),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()

        self.inputAccessoryView = toolbar
    }

    // Default actions:
    @objc func doneButtonTapped() { self.resignFirstResponder() }
    @objc func cancelButtonTapped() { self.resignFirstResponder() }
}

protocol BenchConfigCellDelegate: AnyObject {
    func benchConfigCellDidSubmitConfig(_ cell: BenchConfigCell, type: ConfigOption, chosenValue: Int)
}

class BenchConfigCell: UITableViewCell {
    
    weak var delegate: BenchConfigCellDelegate?

    @IBOutlet weak var configTitle: UILabel!
    @IBOutlet weak var numberInput: UITextField! {
        didSet { numberInput?.addDoneCancelToolbar() }
    }
    
    private var type: ConfigOption?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        numberInput.delegate = self

        self.selectionStyle = SelectionStyle.none
    }
    
    func configure(type: ConfigOption, defaultNumber: Int) {
        configTitle.text = type.rawValue
        self.type = type
        numberInput.text = String(defaultNumber)
    }
}

extension BenchConfigCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let currentText = textField.text,
              let type = type else {
            return false
        }
        let newValue = Int(currentText + string) ?? 0
        
        delegate?.benchConfigCellDidSubmitConfig(self, type: type, chosenValue: newValue)
        return true
    }
}
