//
//  BenchSettingsTableViewController.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-04.
//

import UIKit

class BenchSettingsTableViewController: UITableViewController {
    
    var model: SettingsModel!

    let sectionHeaders = ["Benchmark to run", "Settings", "Benchmark configuration"]
    
    static func make(model: SettingsModel) -> BenchSettingsTableViewController {
        let viewController = BenchSettingsTableViewController(style: .grouped)
        viewController.model = model
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerCells()
    }

    private func registerCells() {
        tableView.register(
            UINib(nibName: "BenchConfigCell", bundle: nil),
            forCellReuseIdentifier: "BenchConfigCell")

        tableView.register(
            UINib(nibName: "BenchPickerCell", bundle: nil),
            forCellReuseIdentifier: "BenchPickerCell")

        tableView.register(
            UINib(nibName: "BenchSelectionCell", bundle: nil),
            forCellReuseIdentifier: "BenchSelectionCell")

        tableView.register(
            UINib(nibName: "BatchModeCell", bundle: nil),
            forCellReuseIdentifier: "BatchModeCell")

        tableView.register(
            UINib(nibName: "ConcurrencyModelSelectionCell", bundle: nil),
            forCellReuseIdentifier: "ConcurrencyModelSelectionCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return model.batchModeOn ? 2 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 2
        case 1:
            return 2
        case 2:
            return model.selectedBenchmarkInstance.configOptions.count
        default:
            print("Error, unknown section")
            return -1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        lazy var benchSelectionCell = tableView.dequeueReusableCell(
            withIdentifier: "BenchSelectionCell",
            for: indexPath)
        as! BenchSelectionCell
        
        lazy var benchPickerCell = tableView.dequeueReusableCell(
            withIdentifier: "BenchPickerCell",
            for: indexPath)
        as! BenchPickerCell
        
        lazy var benchConfigCell = tableView.dequeueReusableCell(
            withIdentifier: "BenchConfigCell",
            for: indexPath)
        as! BenchConfigCell

        lazy var benchBatchModeCell: BatchModeCell = tableView.dequeueReusableCell(
            withIdentifier: "BatchModeCell",
            for: indexPath)
        as! BatchModeCell

        lazy var benchConcurrencyModelSelectionCell: ConcurrencyModelSelectionCell = tableView.dequeueReusableCell(
            withIdentifier: "ConcurrencyModelSelectionCell",
            for: indexPath)
        as! ConcurrencyModelSelectionCell
        
        switch (indexPath.section) {
            
        case 0:
            switch (indexPath.row) {
            case 0:
                benchSelectionCell.configure(chosenBenchmark: model.selectedBenchmark)
                return benchSelectionCell
            case 1:
                benchPickerCell.configure(benchmarks: model.benchmarkTypes)
                benchPickerCell.delegate = self
                return benchPickerCell
            default:
                return UITableViewCell()
            }

        case 1:
            switch (indexPath.row) {
            case 0:
                benchBatchModeCell.configure(isOn: model.batchModeOn)
                benchBatchModeCell.delegate = self
                return benchBatchModeCell
            case 1:
                benchConcurrencyModelSelectionCell.delegate = self
                return benchConcurrencyModelSelectionCell
            default:
                return UITableViewCell()
            }
            
        case 2:
            let options = model.selectedBenchmarkInstance.configOptions
            benchConfigCell.configure(
                type: Array(options.keys)[indexPath.row],
                defaultNumber: Array(options.values)[indexPath.row])
            benchConfigCell.delegate = self
            
            return benchConfigCell
            
        default:
            return UITableViewCell()
        }
    }
}

extension BenchSettingsTableViewController: BenchPickerCellDelegate {

    func benchPickerCellDidSelectBenchmark(_ cell: BenchPickerCell, chosenBenchmark: BenchmarkType) {
        model.selectBenchmark(benchmark: chosenBenchmark)
        tableView.reloadData()
    }
}

extension BenchSettingsTableViewController: BenchConfigCellDelegate {
    
    func benchConfigCellDidSubmitConfig(_ cell: BenchConfigCell, type: ConfigOption, chosenValue: Int) {
        model.configureBenchmark(value: chosenValue, option: type)
    }
}

extension BenchSettingsTableViewController: BatchModeCellDelegate {

    func batchModeCellDidToggle(_ cell: BatchModeCell, isOn: Bool) {
        model.toggleBatchMode(isOn: isOn)

        UIView.transition(with: tableView,
                          duration: 0.2,
                          options: .transitionCrossDissolve, // https://medium.com/@apmason/uiview-animation-options-9510832eedba
                          animations: { self.tableView.reloadData() },
                          completion: nil)
    }
}

extension BenchSettingsTableViewController: ConcurrencyModelCellDelegate {

    func concurrencyModelCellDidSelectModel(_ cell: ConcurrencyModelSelectionCell, selectedModelIndex: Int) {
        model.setConcurrencyModel(concurrencyModelIndex: selectedModelIndex)
    }
}
