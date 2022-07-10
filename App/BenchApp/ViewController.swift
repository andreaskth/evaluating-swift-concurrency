//
//  ViewController.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-04.
//

import UIKit

class ViewController: UIViewController {
    
    private var tableViewController: BenchSettingsTableViewController!
    private var runBenchmarkButton: UIButton!
    
    private let model = SettingsModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setUpTableView()
        setUpBenchmarkButton()
    }

    // https://www.appsdeveloperblog.com/disable-rotation-of-uiviewcontroller/
    override open var shouldAutorotate: Bool {
        return false
    }
    
    private func setUpTableView() {
        
        model.selectBenchmark(benchmark: model.benchmarkTypes[0]) // default
        tableViewController = BenchSettingsTableViewController.make(model: model)
        
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableViewController.view)
        
        NSLayoutConstraint.activate([
            tableViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            
        ])
    }

    private func setUpBenchmarkButton() {
        
        runBenchmarkButton = UIButton()
        runBenchmarkButton.configuration?.buttonSize = UIButton.Configuration.Size.large
        //runBenchmarkButton.frame.size = CGSize(width: 500, height: 1000) <-- TODO: Does not work
        runBenchmarkButton.configuration = UIButton.Configuration.filled()
        runBenchmarkButton.setTitle("▶ Run benchmark", for: .normal)
        
        runBenchmarkButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(runBenchmarkButton)
        
        // https://stackoverflow.com/a/60155041/16823203
        NSLayoutConstraint.activate([
            runBenchmarkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            runBenchmarkButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            runBenchmarkButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50) // TODO: Reconsider
        ])
        
        // https://stackoverflow.com/questions/24102191/make-a-uibutton-programmatically-in-swift
        runBenchmarkButton.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
    }
    
    @objc func onClick(_ sender: UIButton) {
        print("Pressed 'Run benchmark'")
        model.runBenchmark()
    }
}

