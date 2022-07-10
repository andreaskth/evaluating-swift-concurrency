//
//  NQueens.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-05-02.
//
//  Adapted from INNCABS benchmark suite:
//  https://github.com/PeterTh/inncabs/blob/master/nqueens/nqueens.cpp

import Foundation

class NQueens: Benchmark {

    let name = "NQueens"
    var concurrencyModel = ConcurrencyModel.gcd
    var batchMode = true

    var configOptions: [ConfigOption: Int] = [
        .nQueensNumber: 5,
        .iterations: 10,
    ]

    // Correct answers:
    let correct = [1,0,0,2,10,4,40,92,352,724,2680,14200,73712,365596,2279184,14772512,95815104,666090624,4968057848,39029188884,314666222712]

    func run(settingsModel: SettingsModel) {

        concurrencyModel = settingsModel.concurrencyModel
        batchMode = settingsModel.batchModeOn

        print("About to run '\(concurrencyModel.rawValue)'-version of \(self.name) with batch mode: \(batchMode)")

        // Up to 12 works for async-version, 13 leads to crash (out of memory)
        // Up to 5 works for GCD-version, 6+ leads to program blocking
        let queenAmounts = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

        if (batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.batchRunGCD(with: queenAmounts)
                print("Benchmark done")
            }
        } else if (batchMode && concurrencyModel == .sc) {
            Task {
                await batchRunAsync(with: queenAmounts)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.runGCD(numberOfQueens: self.configOptions[.nQueensNumber]!,
                            numberOfIterations: self.configOptions[.iterations]!,
                            iterationsToDiscard: 0)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .sc) {
            Task {
                await runAsync(numberOfQueens: configOptions[.nQueensNumber]!,
                               numberOfIterations: configOptions[.iterations]!,
                               iterationsToDiscard: 0)
                print("Benchmark done")
            }
        }
    }

    private func batchRunAsync(with queenAmounts: [Int]) async {
        for i in 0..<queenAmounts.count {
            let queenAmount = queenAmounts[i]
            await runAsync(numberOfQueens: queenAmount, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }

    private func batchRunGCD(with queenAmounts: [Int]) {
        for i in 0..<queenAmounts.count {
            let queenAmount = queenAmounts[i]
            runGCD(numberOfQueens: queenAmount, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }

    private func runAsync(numberOfQueens: Int, numberOfIterations: Int, iterationsToDiscard: Int) async {

        print("Running \(self):runAsync with \(numberOfQueens) queen(s) and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {
            await self.asyncQueens(n: numberOfQueens)
        }
        print("\n(async, \(numberOfQueens) queens) Done.\n")
    }

    private func runGCD(numberOfQueens: Int, numberOfIterations: Int, iterationsToDiscard: Int) {

        print("Running \(self):runGCD with \(numberOfQueens) queen(s) and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {
            GCDQueens(n: numberOfQueens)
        }
        print("\n(GCD, \(numberOfQueens) queens) Done.\n")
    }

    private func asyncQueens(n: Int) async {

        let _ = await solutionsAsync(n)

        //print("Found \(res) ways to place \(n) queens on \(n)x\(n) board.")
        //precondition(res == correct[n-1], "Incorrect answer for n = \(n)")
    }

    private func GCDQueens(n: Int) {

        let _ = solutionsGCD(n)

        //print("Found \(res) ways to place \(n) queens on \(n)x\(n) board.")
        //precondition(res == correct[n-1], "Incorrect answer for n = \(n)")
    }

    private func solutionsAsync(_ n: Int, _ col: Int = 0, _ history: [Int] = [Int]()) async -> Int {
        if (col == n) {
            return 1 // If we reach this, it means all n queens were placed correctly, hence a solution was found
        } else {
            return await withTaskGroup(of: Int.self) { group in
                for row in 0..<n {
                    let newHistory = history + [row]
                    if (valid(n, col, newHistory)) {
                        group.addTask {
                            await self.solutionsAsync(n, col + 1, newHistory)
                        }
                    }
                }
                return await group.reduce(0, +)
            }
        }
    }

    private func solutionsGCD(_ n: Int, _ col: Int = 0, _ history: [Int] = [Int]()) -> Int {
        if (col == n) {
            return 1 // If we reach this, it means all n queens were placed correctly, hence a solution was found
        } else {
            let group = DispatchGroup()

            var res = 0
            let resUpdateQueue = DispatchQueue(label: "resUpdateQueue")

            for row in 0..<n {
                let newHistory = history + [row]
                if (valid(n, col, newHistory)) {
                    DispatchQueue.global().async(group: group) {
                        let numberOfSolutions = self.solutionsGCD(n, col + 1, newHistory)
                        resUpdateQueue.async {
                            res += numberOfSolutions
                        }
                    }
                }
            }

            group.wait()
            resUpdateQueue.sync {}
            return res
        }
    }

    private func valid(_ n: Int, _ col: Int, _ history: [Int]) -> Bool {
        if (col == 0) {
            return true // col == 0 means no queens have been placed yet, thus 'valid' is trivially true
        }
        let row = history[col]
        for prevCol in 0..<col {
            let prevRow = history[prevCol]
            if (row == prevRow) {
                return false // No two queens on the same row allowed
            }
            if (col - prevCol == abs(row - prevRow)) {
                return false // No two queens on the same diagonal allowed
            }
        }
        return true
    }
}
