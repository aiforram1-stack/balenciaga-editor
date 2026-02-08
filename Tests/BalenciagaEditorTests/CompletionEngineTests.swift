import Testing
@testable import BalenciagaEditor

@Test func completionPrefixReadsIdentifierBeforeCursor() {
    let engine = CompletionEngine()
    let text = "let sampleValue = samp"
    let selection = NSRange(location: text.count, length: 0)

    let prefix = engine.completionPrefix(in: text, selection: selection)

    #expect(prefix == "samp")
}

@Test func suggestionsIncludeIdentifiers() {
    let engine = CompletionEngine()
    let text = "func computeTotal() {\n  let totalRevenue = 1\n  tot\n}"
    let selection = NSRange(location: text.range(of: "tot\n")!.lowerBound.utf16Offset(in: text) + 3, length: 0)

    let results = engine.suggestions(for: text, selection: selection, language: .swift, workspaceFiles: [])

    #expect(results.contains(where: { $0.label == "totalRevenue" }))
}
