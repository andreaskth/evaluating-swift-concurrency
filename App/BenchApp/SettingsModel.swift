//
//  SettingsModel.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-07.
//

import Foundation
import QuartzCore
import UIKit

enum BenchmarkType: String {
    case spawnManyWaiting = "SpawnManyWaiting"
    case spawnManyWaitingGroup = "SpawnManyWaitingGroup"
    case spawnManyActors = "SpawnManyActors"
    case fibonacci = "Fibonacci"
    case nQueens = "NQueens"
    case matrixMultiplication = "MatrixMultiplication"
}

class SettingsModel {
    
    private (set) var selectedBenchmark: BenchmarkType!
    var selectedBenchmarkInstance: Benchmark {
        get { benchmarkInstances[selectedBenchmark]! }
    }

    private (set) var batchModeOn = true

    private (set) var concurrencyModel = ConcurrencyModel.gcd
    private let concurrencyModels = [ConcurrencyModel.gcd, ConcurrencyModel.sc]
    
    // By always accessing benchmarks via this dictionary, we guarantee singleton instances across the entire app (this could/should probably have been handled by a factory method in each respective class)
    var benchmarkInstances: [BenchmarkType: Benchmark] = [
        .spawnManyWaiting: SpawnManyWaiting(),
        .spawnManyWaitingGroup: SpawnManyWaitingGroup(),
        .spawnManyActors: SpawnManyActors(),
        .fibonacci: Fibonacci(),
        .nQueens: NQueens(),
        .matrixMultiplication: MatrixMultiplication()
    ]
    
    // To ensure deterministic ordering in UI
    let benchmarkTypes: [BenchmarkType] = [
        .spawnManyWaiting,
        .spawnManyWaitingGroup,
        .spawnManyActors,
        .fibonacci,
        .nQueens,
        .matrixMultiplication
    ]
    
    func selectBenchmark(benchmark: BenchmarkType) {
        selectedBenchmark = benchmark
    }

    func toggleBatchMode(isOn: Bool) {
        batchModeOn = isOn
    }

    func setConcurrencyModel(concurrencyModelIndex: Int) {
        self.concurrencyModel = concurrencyModels[concurrencyModelIndex]
    }
    
    func configureBenchmark(value: Int, option: ConfigOption) {
        benchmarkInstances[selectedBenchmark]?.configOptions[option] = value
    }
    
    func runBenchmark() {
        startMemorySampling()
        benchmarkInstances[selectedBenchmark]?.run(settingsModel: self)
    }

    // MARK: Memory measurement utilities
    // https://developer.apple.com/documentation/quartzcore/cadisplaylink

    func startMemorySampling() {
        let displaylink = CADisplayLink(target: self, selector: #selector(sample))
        displaylink.add(to: .current, forMode: .default)

        let maxFps = UIScreen.main.maximumFramesPerSecond
        print("Starting memory measurement. Max FPS is \(maxFps) FPS.")
    }

    @objc func sample(displaylink: CADisplayLink) {
        let megaBytes = getMemoryUsage() / 1048576.0 // (= 1024*1024)
        print("\(Date.now), mem: \(megaBytes)")
    }
}
