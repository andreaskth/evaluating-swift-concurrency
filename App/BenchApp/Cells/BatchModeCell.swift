//
//  BatchModeCell.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-05-30.
//

import UIKit

protocol BatchModeCellDelegate: AnyObject {
    func batchModeCellDidToggle(_ cell: BatchModeCell, isOn: Bool)
}

class BatchModeCell: UITableViewCell {

    weak var delegate: BatchModeCellDelegate?

    @IBOutlet weak var toggleSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        toggleSwitch.addTarget(self,
                               action: #selector(switchChanged),
                               for: UIControl.Event.valueChanged)

        self.selectionStyle = SelectionStyle.none
    }

    func configure(isOn: Bool) {
        toggleSwitch.isOn = isOn
    }

    @objc func switchChanged(toggleSwitch: UISwitch) {
        delegate?.batchModeCellDidToggle(self, isOn: toggleSwitch.isOn)
    }

}
