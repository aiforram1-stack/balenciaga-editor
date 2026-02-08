import Foundation

struct GitService {
    private let shell: ShellExecuting

    init(shell: ShellExecuting = ProcessShellExecutor()) {
        self.shell = shell
    }

    func isGitRepository(workspaceURL: URL?) -> Bool {
        guard let workspaceURL else { return false }
        let result = shell.run(["git", "rev-parse", "--is-inside-work-tree"], cwd: workspaceURL)
        return result.exitCode == 0
    }

    func status(workspaceURL: URL?) -> [GitFileStatus] {
        guard let workspaceURL else { return [] }
        let result = shell.run(["git", "status", "--porcelain"], cwd: workspaceURL)
        guard result.exitCode == 0 else { return [] }
        return parsePorcelain(result.stdout)
    }

    func diff(workspaceURL: URL?, filePath: String) -> String {
        guard let workspaceURL else { return "" }
        let statusCode = fileStatusCode(workspaceURL: workspaceURL, filePath: filePath)
        if statusCode == "??" {
            return "Untracked file. Stage it to view full diff output."
        }

        let result = shell.run(["git", "diff", "--", filePath], cwd: workspaceURL)
        if result.exitCode == 0 && !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return result.stdout
        }

        let staged = shell.run(["git", "diff", "--cached", "--", filePath], cwd: workspaceURL)
        if staged.exitCode == 0 && !staged.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return staged.stdout
        }

        return result.stderr.isEmpty ? "No diff available." : result.stderr
    }

    func parsePorcelain(_ output: String) -> [GitFileStatus] {
        output
            .split(separator: "\n")
            .compactMap { line in
                let raw = String(line)
                guard raw.count >= 4 else { return nil }
                let stagedCode = String(raw.prefix(1))
                let unstagedCode = String(raw.dropFirst().prefix(1))
                let pathStartIndex = raw.index(raw.startIndex, offsetBy: 3)
                let path = String(raw[pathStartIndex...]).trimmingCharacters(in: .whitespaces)
                return GitFileStatus(stagedCode: stagedCode, unstagedCode: unstagedCode, path: path)
            }
            .sorted { $0.path < $1.path }
    }

    private func fileStatusCode(workspaceURL: URL, filePath: String) -> String {
        let statuses = status(workspaceURL: workspaceURL)
        guard let match = statuses.first(where: { $0.path == filePath }) else { return "" }
        return match.stagedCode + match.unstagedCode
    }
}
