import Testing
@testable import BalenciagaEditor

@Test func splitModeAssignsSecondaryPane() {
    let appState = AppState()
    appState.autoDiagnosticsEnabled = false
    appState.createNewFile()

    appState.setSplitMode(.vertical)

    #expect(appState.splitMode == .vertical)
    #expect(appState.secondaryTabID != nil)
}

@Test func applyCompletionReplacesCurrentPrefix() {
    let appState = AppState()
    appState.autoDiagnosticsEnabled = false
    appState.createNewFile()
    guard let tabID = appState.primaryTabID,
          let tabIndex = appState.tabs.firstIndex(where: { $0.id == tabID }) else {
        Issue.record("Expected primary tab")
        return
    }

    appState.tabs[tabIndex].text = "let result = valu"
    appState.tabs[tabIndex].lastSelection = NSRange(location: appState.tabs[tabIndex].text.count, length: 0)

    let item = CompletionItem(label: "value", insertText: "value", detail: "symbol")
    appState.applyCompletion(item, pane: .primary)

    #expect(appState.tabs[tabIndex].text == "let result = value")
    #expect(appState.tabs[tabIndex].lastSelection.location == "let result = value".count)
}

@Test func settingFocusedPaneSwitchesActiveTabID() {
    let appState = AppState()
    appState.autoDiagnosticsEnabled = false
    appState.createNewFile()
    appState.createNewFile()
    let first = appState.tabs[0].id
    let second = appState.tabs[1].id

    appState.setTab(first, for: .primary)
    appState.setTab(second, for: .secondary)

    appState.setFocusedPane(.secondary)
    #expect(appState.activeTabID == second)

    appState.setFocusedPane(.primary)
    #expect(appState.activeTabID == first)
}
