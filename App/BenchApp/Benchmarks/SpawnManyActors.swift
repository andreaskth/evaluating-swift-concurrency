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

        for _ in 1...numberOfIterations {
            await self.asyncSpawnMany(n: numberOfActors)
        }
        print("\n(async, \(numberOfActors) actors) Done.\n")
    }
    
    private func runGCD(numberOfActors: Int, numberOfIterations: Int, iterationsToDiscard: Int) {
        
        print("Running \(self):runGCD with \(numberOfActors) actor(s) and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {
            GCDSpawnMany(n: numberOfActors)
        }
        print("\n(GCD, \(numberOfActors) actors) Done.\n")
    }
    
    private func asyncSpawnMany(n: Int) async {
        for _ in 1...n {
            await (Actor()).inc()
        }
    }
    
    private func GCDSpawnMany(n: Int) {
        for _ in 1...n {
            GCDActor().inc()
        }
    }
}
