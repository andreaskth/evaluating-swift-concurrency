//
//  SpawnManyActors.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-20.
//
//  Inspiration: https://forums.swift.org/t/swift-concurrency-roadmap/41611

import Foundation

actor Actor {

    private var counter = 0
    
    func inc() {
        self.counter += 1
    }
}

class GCDActor {

    private var counter = 0
    private let counterQueue = DispatchQueue(label: "GCDActor")
    
    func inc() {
        counterQueue.sync {
            self.counter += 1
        }
    }
}

class SpawnManyActors: Benchmark {
    
    let name = "SpawnManyActors"
    var concurrencyModel = ConcurrencyModel.gcd
    var batchMode = true
    
    var configOptions: [ConfigOption: Int] = [
        .actors: 100,
        .iterations: 10,
    ]
    
    func run(settingsModel: SettingsModel) {

        concurrencyModel = settingsModel.concurrencyModel
        batchMode = settingsModel.batchModeOn

        print("About to run '\(concurrencyModel.rawValue)'-version of \(self.name) with batch mode: \(batchMode)")
        
        let actorAmounts = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]

        if (batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.batchRunGCD(with: actorAmounts)
                print("Benchmark done")
            }
        } else if (batchMode && concurrencyModel == .sc) {
            Task {
                await batchRunAsync(with: actorAmounts)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.runGCD(numberOfActors: self.configOptions[.actors]!,
                            numberOfIterations: self.configOptions[.iterations]!,
                            iterationsToDiscard: 0)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .sc) {
            Task {
                await runAsync(numberOfActors: configOptions[.actors]!,
                               numberOfIterations: configOptions[.iterations]!,
                               iterationsToDiscard: 0)
                print("Benchmark done")
            }
        }
    }
    
    private func batchRunAsync(with actorAmounts: [Int]) async {
        for i in 0..<actorAmounts.count {
            let actorAmount = actorAmounts[i]
            await runAsync(numberOfActors: actorAmount, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }
    
    private func batchRunGCD(with actorAmounts: [Int]) {
        for i in 0..<actorAmounts.count {
            let actorAmount = actorAmounts[i]
            runGCD(numberOfActors: actorAmount, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }
    
    private func runAsync(numberOfActors: Int, numberOfIterations: Int, iterationsToDiscard: Int) async {
        
        print("Running \(self):runAsync with \(numberOfActors) actor(s) and \(numberOfIterations) iteration(s).\n")
        
        var asyncTotalTime: Double = 0
        for i in 1...numberOfIterations {

            let time = await self.asyncSpawnMany(n: numberOfActors)
            
            if i > iterationsToDiscard {
                asyncTotalTime += time
            }
        }
        let asyncAvgTime = String(asyncTotalTime/Double(numberOfIterations-iterationsToDiscard))
        print("\n(async, average, \(numberOfActors) actors) Done in an average of \(asyncAvgTime) seconds.\n")
    }
    
    private func runGCD(numberOfActors: Int, numberOfIterations: Int, iterationsToDiscard: Int) {
        
        print("Running \(self):runGCD with \(numberOfActors) actor(s) and \(numberOfIterations) iteration(s).\n")
        
        var GCDTotalTime: Double = 0
        for i in 1...numberOfIterations {
            
            let time = GCDSpawnMany(n: numberOfActors)
            
            if i > iterationsToDiscard {
                GCDTotalTime += time
            }
        }
        let GCDAvgTime = String(GCDTotalTime/Double(numberOfIterations-iterationsToDiscard))
        print("\n(GCD, average, \(numberOfActors) actors) Done in an average of \(GCDAvgTime) seconds.\n")
    }
    
    private func asyncSpawnMany(n: Int) async -> TimeInterval {
        
        let before = ProcessInfo.processInfo.systemUptime
        
        for _ in 1...n {
            await (Actor()).inc()
        }
        
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before
        
        print(time)
        
        return time
    }
    
    private func GCDSpawnMany(n: Int) -> TimeInterval {
        
        let before = ProcessInfo.processInfo.systemUptime
        
        for _ in 1...n {
            GCDActor().inc()
        }
        
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before
        
        print(time)
        
        return time
    }
}
