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
        
        var asyncTotalTime: Double = 0
        for i in 1...numberOfIterations {
            
            let time = await self.asyncSpawnMany(n: numberOfTasks)
            
            if i > iterationsToDiscard {
                asyncTotalTime += time
            }
        }
        let asyncAvgTime = String(asyncTotalTime/Double(numberOfIterations-iterationsToDiscard))
        print("\n(async, average, \(numberOfTasks) tasks) Done in an average of \(asyncAvgTime) seconds.\n")
    }
    
    private func runGCD(numberOfTasks: Int, numberOfIterations: Int, iterationsToDiscard: Int) {
        
        print("Running \(self):runGCD with \(numberOfTasks) task(s) and \(numberOfIterations) iteration(s).\n")
        
        var GCDTotalTime: Double = 0
        for i in 1...numberOfIterations {
            
            let time = GCDSpawnMany(n: numberOfTasks)
            
            if i > iterationsToDiscard {
                GCDTotalTime += time
            }
        }
        let GCDAvgTime = String(GCDTotalTime/Double(numberOfIterations-iterationsToDiscard))
        print("\n(GCD, average, \(numberOfTasks) tasks) Done in an average of \(GCDAvgTime) seconds.\n")
    }
    
    private func asyncSpawnMany(n: Int) async -> TimeInterval {
        
        let before = ProcessInfo.processInfo.systemUptime
        
        for _ in 1...n {
            let _ = await Task {
                try await Task.sleep(nanoseconds: 100_000_000)
            }.result
        }
        
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before
        
        print(time)
        
        return time
    }
    
    private func GCDSpawnMany(n: Int) -> TimeInterval {
        
        let before = ProcessInfo.processInfo.systemUptime
        
        for _ in 1...n {
            let _ = DispatchQueue.global().sync() {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before
        
        print(time)
        
        return time
    }
}
