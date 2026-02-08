import Foundation

struct ShellResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

protocol ShellExecuting {
    func run(_ arguments: [String], cwd: URL?) -> ShellResult
}

struct ProcessShellExecutor: ShellExecuting {
    func run(_ arguments: [String], cwd: URL?) -> ShellResult {
        guard let executable = arguments.first else {
            return ShellResult(exitCode: 1, stdout: "", stderr: "missing executable")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + Array(arguments.dropFirst())
        if let cwd {
            process.currentDirectoryURL = cwd
        }

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ShellResult(exitCode: 1, stdout: "", stderr: error.localizedDescription)
        }

        let stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        return ShellResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr)
    }
}
