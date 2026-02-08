import Testing
@testable import BalenciagaEditor

@Test func parsePorcelainOutput() {
    let service = GitService()
    let output = " M Sources/main.swift\nA  README.md\n?? Notes.txt\n"

    let statuses = service.parsePorcelain(output)

    #expect(statuses.count == 3)
    #expect(statuses[0].path == "Notes.txt")
    #expect(statuses[1].displayCode == "A-")
    #expect(statuses[2].displayCode == "-M")
}
