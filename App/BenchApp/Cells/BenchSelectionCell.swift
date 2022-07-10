//
//  BenchSelectionCell.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-04.
//

import UIKit

class BenchSelectionCell: UITableViewCell {

    private var tableViewController: BenchSettingsTableViewController!

    @IBOutlet weak var benchmarkButton: UIButton!
    
    @IBAction func onClick(_ sender: Any) {
        // TODO: Add code to hide/display picker
    }
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        self.selectionStyle = SelectionStyle.none
    }
    
    func configure(chosenBenchmark: BenchmarkType) {
        benchmarkButton.setTitle(chosenBenchmark.rawValue, for: .normal)
    }
}
