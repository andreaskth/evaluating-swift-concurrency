//
//  MatrixMultiplication.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-07.
//

import Foundation

class MatrixMultiplication: Benchmark {

    let name = "MatrixMultiplication"
    var concurrencyModel = ConcurrencyModel.gcd
    var batchMode = true
    
    var configOptions: [ConfigOption: Int] = [
        .matrixRows: 100,
        .matrixColumns: 100,
        .iterations: 10,
    ]

    func run(settingsModel: SettingsModel) {

        concurrencyModel = settingsModel.concurrencyModel
        batchMode = settingsModel.batchModeOn

        print("About to run '\(concurrencyModel.rawValue)'-version of \(self.name) with batch mode: \(batchMode)")

        // Currently only using square matrices
        let matrixDimensions = [25, 50, 75, 100]

        srand48(12345)

        if (batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.batchRunGCD(with: matrixDimensions)
                print("Benchmark done")
            }
        } else if (batchMode && concurrencyModel == .sc) {
            Task {
                await batchRunAsync(with: matrixDimensions)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .gcd) {
            DispatchQueue.global().async {
                self.runGCD(matrixRows: self.configOptions[.matrixRows]!,
                            matrixColumns: self.configOptions[.matrixColumns]!,
                            numberOfIterations: self.configOptions[.iterations]!,
                            iterationsToDiscard: 0)
                print("Benchmark done")
            }
        } else if (!batchMode && concurrencyModel == .sc) {
            Task {
                await runAsync(matrixRows: self.configOptions[.matrixRows]!,
                               matrixColumns: self.configOptions[.matrixColumns]!,
                               numberOfIterations: configOptions[.iterations]!,
                               iterationsToDiscard: 0)
                print("Benchmark done")
            }
        }
    }

    private func batchRunAsync(with matrixDimensions: [Int]) async {
        for i in 0..<matrixDimensions.count {
            let matrixDimension = matrixDimensions[i]
            await runAsync(matrixRows: matrixDimension, matrixColumns: matrixDimension, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }

    private func batchRunGCD(with matrixDimensions: [Int]) {
        for i in 0..<matrixDimensions.count {
            let matrixDimension = matrixDimensions[i]
            runGCD(matrixRows: matrixDimension, matrixColumns: matrixDimension, numberOfIterations: 110, iterationsToDiscard: 10)
        }
    }

    private func runAsync(matrixRows: Int, matrixColumns: Int, numberOfIterations: Int, iterationsToDiscard: Int) async {

        print("Running \(self):runAsync with (\(matrixRows)x\(matrixColumns)) matrix and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {

            let A: [[Int]] = generateMatrix(matrixRows: matrixRows, matrixColumns: matrixColumns)
            let B: [[Int]] = generateMatrix(matrixRows: matrixRows, matrixColumns: matrixColumns)

            let _ = await self.asyncMatrixMult(leftMatrix: A, rightMatrix: B)
        }
        print("\n(async, (\(matrixRows)x\(matrixColumns)) matrix) Done.\n")
    }

    private func runGCD(matrixRows: Int, matrixColumns: Int, numberOfIterations: Int, iterationsToDiscard: Int) {

        print("Running \(self):runGCD with (\(matrixRows)x\(matrixColumns)) matrix and \(numberOfIterations) iteration(s).\n")

        for _ in 1...numberOfIterations {

            let A: [[Int]] = generateMatrix(matrixRows: matrixRows, matrixColumns: matrixColumns)
            let B: [[Int]] = generateMatrix(matrixRows: matrixRows, matrixColumns: matrixColumns)

            let _ = GCDMatrixMult(leftMatrix: A, rightMatrix: B)
        }
        print("\n(GCD, (\(matrixRows)x\(matrixColumns)) matrix) Done.\n")
    }

    actor Matrix {

        private var m: [[Int]]

        init(size: Int) {
            m = [[Int]](repeating: [Int](repeating: 0, count: size), count: size)
        }

        func update(row: Int, column: Int, newValue: Int) {
            m[row][column] = newValue
        }

        func get() -> [[Int]] {
            return m
        }
    }

    private func asyncMatrixMult(leftMatrix: [[Int]], rightMatrix: [[Int]]) async -> [[Int]] {

        let res = Matrix(size: leftMatrix.count)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<leftMatrix.count {
                for j in 0..<rightMatrix[0].count {
                    group.addTask() {
                        let ownRow = leftMatrix[i]
                        let otherColumn = rightMatrix.map { $0[j] }
                        let cellRes = self.dotProduct(ownRow, otherColumn)
                        await res.update(row: i, column: j, newValue: cellRes)
                    }
                }
            }
        }
        return await res.get()
    }

    private func GCDMatrixMult(leftMatrix: [[Int]], rightMatrix: [[Int]]) -> [[Int]] {

        let group = DispatchGroup()

        var res = [[Int]](repeating: [Int](repeating: 0, count: leftMatrix.count), count: rightMatrix[0].count)
        let resUpdateQueue = DispatchQueue(label: "resUpdateQueue")

        for i in 0..<leftMatrix.count {
            for j in 0..<rightMatrix[0].count {
                DispatchQueue.global().async(group: group) {
                    let ownRow = leftMatrix[i]
                    let otherColumn = rightMatrix.map { $0[j] }
                    let cellRes = self.dotProduct(ownRow, otherColumn)
                    resUpdateQueue.sync {
                        res[i][j] = cellRes
                    }
                }
            }
        }

        group.wait()

        return res
    }

    private func dotProduct(_ arr1: [Int], _ arr2: [Int]) -> Int {
        var sum = 0
        for i in 0..<arr1.count {
            sum += arr1[i] * arr2[i]
        }
        return sum
    }

    private func generateMatrix(matrixRows: Int, matrixColumns: Int) -> [[Int]] {
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: matrixColumns), count: matrixRows)
        for i in 0..<matrixRows {
            for j in 0..<matrixColumns {
                matrix[i][j] = Int(drand48() * 1000)
            }
        }
        return matrix
    }

    private func printMatrix(matrix: [[Int]]) {
        for i in 0..<matrix.count {
            for j in 0..<matrix[0].count {
                print("\(matrix[i][j]), ", terminator: "")
            }
            print()
        }
    }

    private func verifyMult() {
        let leftMatrix = [
            [684, 582, 269],
            [390, 293, 742],
            [298, 75, 404]
        ]
        let rightMatrix = [
            [857, 941, 662],
            [846, 2, 462],
            [532, 787, 265]
        ]
        let expected = [
            [1221668, 856511, 792977],
            [976852, 951530, 590176],
            [533764, 598516, 338986]
        ]

        let actualGCD = GCDMatrixMult(leftMatrix: leftMatrix, rightMatrix: rightMatrix)
        precondition(expected == actualGCD, "GCD matrix multiplication went wrong")

        Task {
            let actualAsync = await asyncMatrixMult(leftMatrix: leftMatrix, rightMatrix: rightMatrix)
            precondition(expected == actualAsync, "Async matrix multiplication went wrong")
        }
    }
}
