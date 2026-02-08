import Testing
@testable import BalenciagaEditor

@Test func structuralDiagnosticsFindsTrailingWhitespaceAndUnbalancedPairs() {
    let engine = DiagnosticsEngine()
    let diagnostics = engine.structuralDiagnostics(for: "func x() {  \n")

    #expect(diagnostics.contains(where: { $0.message.contains("Unbalanced braces") }))
    #expect(diagnostics.contains(where: { $0.message == "Trailing whitespace" }))
}

@Test func compilerDiagnosticParserExtractsLineColumnAndSeverity() {
    let engine = DiagnosticsEngine()
    let output = "/tmp/file.swift:12:8: error: cannot find 'x' in scope"

    let diagnostics = engine.parseCompilerDiagnostics(output: output)

    #expect(diagnostics.count == 1)
    #expect(diagnostics.first?.line == 12)
    #expect(diagnostics.first?.column == 8)
    #expect(diagnostics.first?.severity == .error)
    #expect(diagnostics.first?.message == "cannot find 'x' in scope")
}

@Test func jsonDiagnosticsDetectInvalidJson() {
    let engine = DiagnosticsEngine()
    let diagnostics = engine.diagnostics(for: "{ invalid", language: .json, fileURL: nil)

    #expect(!diagnostics.isEmpty)
    #expect(diagnostics.contains(where: { $0.severity == .error }))
}
