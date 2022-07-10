//
//  Benchmark.swift
//  BenchApp
//
//  Created by Andreas Kärrby on 2022-04-07.
//

import Foundation

enum ConfigOption: String {
    case tasks = "Number of tasks"
    case actors = "Number of actors"
    case iterations = "Number of iterations"
    case fibNumber = "Fibonacci number to calculate"
    case nQueensNumber = "Number of queens to place"
    case matrixRows = "Number of matrix rows"
    case matrixColumns = "Number of matrix columns"
}

enum ConcurrencyModel: String {
    case gcd = "GCD"
    case sc  = "Swift concurrency"
}

/// Returns memory usage in bytes.
/// (https://stackoverflow.com/a/64738201/16823203)
func getMemoryUsage() -> Double {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
    let _: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    let usedBytes = Double(taskInfo.phys_footprint)
    return usedBytes

    //let usedMb = usedBytes / 1048576.0
    //let totalGb = Float(ProcessInfo.processInfo.physicalMemory) / (1048576.0 * 1024)
}

protocol Benchmark {
    
    var name: String { get } // NB: Keep to max 30 characters to not overflow screen
    
    var configOptions: [ConfigOption: Int] { get set }
    
    func run(settingsModel: SettingsModel)
}
