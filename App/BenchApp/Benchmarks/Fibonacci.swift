//
//  Fibonacci.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-07.

import Foundation

class Fibonacci: Benchmark {

    let name = "Fibonacci"
    var concurrencyModel = ConcurrencyModel.gcd
    var batchMode = true
    
    var configOptions: [ConfigOption: Int] = [
        .fibNumber: 30,
        .iterations: 10,
    ]

    // Correct answers (first 30 numbers):
    let correct = [0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946,17711,28657,46368,75025,121393,196418,317811,514229,832040]
    
    func run(settingsModel: SettingsModel) {

        concurrencyModel = settingsModel.concurrencyModel
        batchMode = settingsModel.batchModeOn

        print("About to run '\(concurrencyModel.rawValue)'-version of \(self.name) with batch mode: \(batchMode)")

        // fib(30) with GCD -Onone takes ~1.77 seconds
        let fibNumbers = [5, 10, 15, 20, 25]

        if (batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.batchRunGCD(with: fibNumbers)
                print("Benchmark done")
            }
        } else if (batchMode && concurrencyModel == .sc) {
            Task {
                await batchRunAsync(with: fibNumbers)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.runGCD(fibNumber: self.configOptions[.fibNumber]!,
                            numberOfIterations: self.configOptions[.iterations]!,
                            iterationsToDiscard: 0)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .sc) {
            Task {
                await runAsync(fibNumber: configOptions[.fibNumber]!,
                               numberOfIterations: configOptions[.iterations]!,
                               iterationsToDiscard: 0)
                print("Benchmark done")
            }
        }
    }

    private func batchRunAsync(with fibNumbers: [Int]) async {
        for i in 0..<fibNumbers.count {
            let fibNumber = fibNumbers[i]
            await runAsync(fibNumber: fibNumber, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }

    private func batchRunGCD(with fibNumbers: [Int]) {
        for i in 0..<fibNumbers.count {
            let fibNumber = fibNumbers[i]
            runGCD(fibNumber: fibNumber, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }

    private func runAsync(fibNumber: Int, numberOfIterations: Int, iterationsToDiscard: Int) async {

        print("Running \(self):runAsync with fib(\(fibNumber)) and \(numberOfIterations) iteration(s).\n")

        var asyncTotalTime: Double = 0
        for i in 1...numberOfIterations {

            let time = await self.asyncFib(fibNumber: fibNumber)

            if i > iterationsToDiscard {
                asyncTotalTime += time
            }
        }
        let asyncAvgTime = String(asyncTotalTime/Double(numberOfIterations-iterationsToDiscard))
        print("\n(async, average, fib(\(fibNumber)) Done in an average of \(asyncAvgTime) seconds.\n")
    }

    private func runGCD(fibNumber: Int, numberOfIterations: Int, iterationsToDiscard: Int) {

        print("Running \(self):runGCD with fib(\(fibNumber)) and \(numberOfIterations) iteration(s).\n")

        var GCDTotalTime: Double = 0
        for i in 1...numberOfIterations {

            let time = GCDFib(fibNumber: fibNumber)

            if i > iterationsToDiscard {
                GCDTotalTime += time
            }
        }
        let GCDAvgTime = String(GCDTotalTime/Double(numberOfIterations-iterationsToDiscard))
        print("\n(GCD, average, fib(\(fibNumber))) Done in an average of \(GCDAvgTime) seconds.\n")
    }

    private func asyncFib(fibNumber: Int) async -> TimeInterval {

        let before = ProcessInfo.processInfo.systemUptime
        let res = await fib(fibNumber)
        let after = ProcessInfo.processInfo.systemUptime
        let time = after - before

        //print("fib(\(fibNumber)) is: \(String(res))")
        //precondition(res == correct[fibNumber], "Incorrect answer for n = \(fibNumber)")

        print(time)

        return time
    }

    private func GCDFib(fibNumber: Int) -> TimeInterval {

        let semaphore = DispatchSemaphore(value: 0)
        var time: TimeInterval = 0
        let before = ProcessInfo.processInfo.systemUptime
        fib(fibNumber) { res in
            let after = ProcessInfo.processInfo.systemUptime
            time = after - before
            print(time)
            //print("fib(\(fibNumber)) is: \(String(res))")
            //precondition(res == self.correct[fibNumber], "Incorrect answer for n = \(fibNumber)")
            semaphore.signal()
        }
        semaphore.wait()

        return time
    }

    private func fib(_ n: Int) async -> Int {
        if (n < 2) {
            return n
        }
        async let res  = fib(n-1)
        async let res2 = fib(n-2)
        return await res+res2
    }

    private func fib(_ n: Int, ch: @escaping (Int) -> Void) {
        if (n < 2) {
            ch(n)
            return
        }
        DispatchQueue.global().async {
            self.fib(n-1) { res in
                self.fib(n-2) { res2 in
                    ch(res+res2)
                }
            }
        }
    }
}
