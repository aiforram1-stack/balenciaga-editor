import Foundation

struct DiagnosticsEngine {
    private let shell: ShellExecuting

    init(shell: ShellExecuting = ProcessShellExecutor()) {
        self.shell = shell
    }

    func diagnostics(for text: String, language: Language, fileURL: URL?) -> [DiagnosticItem] {
        var results = structuralDiagnostics(for: text)

        switch language {
        case .json:
            results.append(contentsOf: jsonDiagnostics(for: text))
        case .swift:
            results.append(contentsOf: swiftDiagnostics(for: text, fileURL: fileURL))
        case .javascript:
            results.append(contentsOf: javaScriptDiagnostics(for: text, ext: "js"))
        case .typescript:
            results.append(contentsOf: javaScriptDiagnostics(for: text, ext: "ts"))
        case .python:
            results.append(contentsOf: pythonDiagnostics(for: text))
        default:
            break
        }

        return deduplicated(results).sorted { lhs, rhs in
            if lhs.line == rhs.line { return lhs.column < rhs.column }
            return lhs.line < rhs.line
        }
    }

    private func jsonDiagnostics(for text: String) -> [DiagnosticItem] {
        do {
            let data = Data(text.utf8)
            _ = try JSONSerialization.jsonObject(with: data)
            return []
        } catch {
            let message = error.localizedDescription
            return [DiagnosticItem(severity: .error, line: 1, column: 1, message: "JSON: \(message)")]
        }
    }

    private func swiftDiagnostics(for text: String, fileURL: URL?) -> [DiagnosticItem] {
        let ext = fileURL?.pathExtension.isEmpty == false ? (fileURL?.pathExtension ?? "swift") : "swift"
        let sourceURL = temporaryURL(extension: ext)
        do {
            try text.write(to: sourceURL, atomically: true, encoding: .utf8)
        } catch {
            return [DiagnosticItem(severity: .warning, line: 1, column: 1, message: "Unable to stage Swift diagnostics")] 
        }

        let result = shell.run(["swiftc", "-typecheck", sourceURL.path], cwd: sourceURL.deletingLastPathComponent())
        try? FileManager.default.removeItem(at: sourceURL)
        if result.exitCode == 0 { return [] }

        return parseCompilerDiagnostics(output: result.stderr + "\n" + result.stdout)
    }

    private func javaScriptDiagnostics(for text: String, ext: String) -> [DiagnosticItem] {
        let sourceURL = temporaryURL(extension: ext)
        do {
            try text.write(to: sourceURL, atomically: true, encoding: .utf8)
        } catch {
            return [DiagnosticItem(severity: .warning, line: 1, column: 1, message: "Unable to stage JS/TS diagnostics")]
        }

        let checkResult: ShellResult
        if ext == "js" {
            checkResult = shell.run(["node", "--check", sourceURL.path], cwd: sourceURL.deletingLastPathComponent())
        } else {
            // tsc is optional; when unavailable, fall back to node syntax check semantics.
            let tscResult = shell.run(["tsc", "--noEmit", sourceURL.path], cwd: sourceURL.deletingLastPathComponent())
            checkResult = tscResult.exitCode == 127 ? shell.run(["node", "--check", sourceURL.path], cwd: sourceURL.deletingLastPathComponent()) : tscResult
        }

        try? FileManager.default.removeItem(at: sourceURL)
        if checkResult.exitCode == 0 { return [] }
        return parseCompilerDiagnostics(output: checkResult.stderr + "\n" + checkResult.stdout)
    }

    private func pythonDiagnostics(for text: String) -> [DiagnosticItem] {
        let sourceURL = temporaryURL(extension: "py")
        do {
            try text.write(to: sourceURL, atomically: true, encoding: .utf8)
        } catch {
            return [DiagnosticItem(severity: .warning, line: 1, column: 1, message: "Unable to stage Python diagnostics")]
        }

        let result = shell.run(["python3", "-m", "py_compile", sourceURL.path], cwd: sourceURL.deletingLastPathComponent())
        try? FileManager.default.removeItem(at: sourceURL)
        if result.exitCode == 0 { return [] }
        return parseCompilerDiagnostics(output: result.stderr + "\n" + result.stdout)
    }

    func parseCompilerDiagnostics(output: String) -> [DiagnosticItem] {
        let pattern = #":(\d+):(\d+):\s+(error|warning|note):\s+(.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = output as NSString
        let range = NSRange(location: 0, length: nsText.length)
        var diagnostics: [DiagnosticItem] = []

        regex.enumerateMatches(in: output, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges == 5 else { return }
            let lineText = nsText.substring(with: match.range(at: 1))
            let colText = nsText.substring(with: match.range(at: 2))
            let severityText = nsText.substring(with: match.range(at: 3)).lowercased()
            let message = nsText.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)

            let severity: DiagnosticItem.Severity
            switch severityText {
            case "error": severity = .error
            case "warning": severity = .warning
            default: severity = .info
            }

            diagnostics.append(
                DiagnosticItem(
                    severity: severity,
                    line: Int(lineText) ?? 1,
                    column: Int(colText) ?? 1,
                    message: message
                )
            )
        }

        if diagnostics.isEmpty, !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(DiagnosticItem(severity: .warning, line: 1, column: 1, message: output.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return diagnostics
    }

    func structuralDiagnostics(for text: String) -> [DiagnosticItem] {
        let pairs: [(Character, Character, String)] = [
            ("{", "}", "brace"),
            ("(", ")", "parenthesis"),
            ("[", "]", "bracket")
        ]

        var diagnostics: [DiagnosticItem] = []
        for pair in pairs {
            let delta = text.filter { $0 == pair.0 }.count - text.filter { $0 == pair.1 }.count
            if delta != 0 {
                diagnostics.append(
                    DiagnosticItem(
                        severity: .warning,
                        line: 1,
                        column: 1,
                        message: "Unbalanced \(pair.2)s detected"
                    )
                )
            }
        }

        let lines = text.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            if line.hasSuffix(" ") || line.hasSuffix("\t") {
                diagnostics.append(
                    DiagnosticItem(
                        severity: .info,
                        line: index + 1,
                        column: max(line.count, 1),
                        message: "Trailing whitespace"
                    )
                )
            }
        }

        return diagnostics
    }

    private func deduplicated(_ diagnostics: [DiagnosticItem]) -> [DiagnosticItem] {
        var seen = Set<String>()
        var results: [DiagnosticItem] = []

        for item in diagnostics {
            let key = "\(item.severity.rawValue)-\(item.line)-\(item.column)-\(item.message)"
            if seen.insert(key).inserted {
                results.append(item)
            }
        }

        return results
    }

    private func temporaryURL(extension ext: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("balenciaga-lint-\(UUID().uuidString).\(ext)")
    }
}
