//
//  SpawnManyWaiting.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-21.

import Foundation

class SpawnManyWaiting: Benchmark {
    
    let name = "SpawnManyWaiting"
    var concurrencyModel = ConcurrencyModel.gcd
    var batchMode = true
    
    var configOptions: [ConfigOption: Int] = [
        .tasks: 100,
        .iterations: 10,
    ]

    func run(settingsModel: SettingsModel) {

        concurrencyModel = settingsModel.concurrencyModel
        batchMode = settingsModel.batchModeOn

        print("About to run '\(concurrencyModel.rawValue)'-version of \(self.name) with batch mode: \(batchMode)")

        let taskAmounts = [2, 4, 6, 8, 10]

        if (batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.batchRunGCD(with: taskAmounts)
                print("Benchmark done")
            }
        } else if (batchMode && concurrencyModel == .sc) {
            Task {
                await batchRunAsync(with: taskAmounts)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.runGCD(numberOfTasks: self.configOptions[.tasks]!,
                            numberOfIterations: self.configOptions[.iterations]!,
                            iterationsToDiscard: 0)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .sc) {
            Task {
                await runAsync(numberOfTasks: configOptions[.tasks]!,
                               numberOfIterations: configOptions[.iterations]!,
                               iterationsToDiscard: 0)
                print("Benchmark done")
            }
        }
    }
    
    private func batchRunAsync(with taskAmounts: [Int]) async {
        for i in 0..<taskAmounts.count {
            let taskAmount = taskAmounts[i]
            await runAsync(numberOfTasks: taskAmount, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }
    
    private func batchRunGCD(with taskAmounts: [Int]) {
        for i in 0..<taskAmounts.count {
            let taskAmount = taskAmounts[i]
            runGCD(numberOfTasks: taskAmount, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }
    
    private func runAsync(numberOfTasks: Int, numberOfIterations: Int, iterationsToDiscard: Int) async {
        
        print("Running \(self):runAsync with \(numberOfTasks) task(s) and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {
            await self.asyncSpawnMany(n: numberOfTasks)
        }
        print("\n(async, \(numberOfTasks) tasks) Done.\n")
    }
    
    private func runGCD(numberOfTasks: Int, numberOfIterations: Int, iterationsToDiscard: Int) {
        
        print("Running \(self):runGCD with \(numberOfTasks) task(s) and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {
            GCDSpawnMany(n: numberOfTasks)
        }
        print("\n(GCD, \(numberOfTasks) tasks) Done.\n")
    }
    
    private func asyncSpawnMany(n: Int) async {
        for _ in 1...n {
            let _ = await Task {
                try await Task.sleep(nanoseconds: 100_000_000)
            }.result
        }
    }
    
    private func GCDSpawnMany(n: Int) {
        for _ in 1...n {
            let _ = DispatchQueue.global().sync() {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}
