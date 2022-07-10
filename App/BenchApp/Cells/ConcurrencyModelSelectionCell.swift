//
//  ConcurrencyModelSelectionCell.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-05-30.
//

import UIKit

protocol ConcurrencyModelCellDelegate: AnyObject {
    func concurrencyModelCellDidSelectModel(_ cell: ConcurrencyModelSelectionCell, selectedModelIndex: Int)
}

class ConcurrencyModelSelectionCell: UITableViewCell {

    weak var delegate: ConcurrencyModelCellDelegate?

    @IBOutlet weak var segmentedControl: UISegmentedControl!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        segmentedControl.addTarget(self,
                                 action: #selector(segmentedControlChanged),
                                 for: UIControl.Event.valueChanged)

        self.selectionStyle = SelectionStyle.none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func segmentedControlChanged(segmentedControl: UISegmentedControl) {
        let selectedModelIndex = segmentedControl.selectedSegmentIndex // TODO: Maybe use enum here instead
        delegate?.concurrencyModelCellDidSelectModel(self, selectedModelIndex: selectedModelIndex)
    }
}
