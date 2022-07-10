//
//  SpawnManyWaitingGroup.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-07.

import Foundation

class SpawnManyWaitingGroup: Benchmark {
    
    let name = "SpawnManyWaitingGroup"
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
        
        let taskAmounts = [50, 100, 150, 200, 250, 300]

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
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 1...n {
                group.addTask {
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
        
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before
        
        print(time)
        
        return time
    }
    
    private func GCDSpawnMany(n: Int) -> TimeInterval {
        
        let before = ProcessInfo.processInfo.systemUptime
        
        let group = DispatchGroup()
        for _ in 1...n {
            DispatchQueue.global().async(group: group) {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        group.wait()
        
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before

        print(time)

        return time
    }
}
