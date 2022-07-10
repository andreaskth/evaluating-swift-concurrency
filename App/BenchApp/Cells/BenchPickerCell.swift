//
//  BenchSelectionCell.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-04.
//

import UIKit

protocol BenchPickerCellDelegate: AnyObject {
    func benchPickerCellDidSelectBenchmark(_ cell: BenchPickerCell, chosenBenchmark: BenchmarkType)
}

// https://medium.com/@raj.amsarajm93/create-dropdown-using-uipickerview-4471e5c7d898
class BenchPickerCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    weak var delegate: BenchPickerCellDelegate?
    private var benchmarks: [BenchmarkType] = []
    
    @IBOutlet weak var picker: UIPickerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.picker.delegate = self
        self.picker.dataSource = self
    }
    
    func configure(benchmarks: [BenchmarkType]) {
        self.benchmarks = benchmarks
    }
    
    // MARK: - Picker view data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return benchmarks.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return benchmarks[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.benchPickerCellDidSelectBenchmark(self, chosenBenchmark: benchmarks[row])
    }
}
