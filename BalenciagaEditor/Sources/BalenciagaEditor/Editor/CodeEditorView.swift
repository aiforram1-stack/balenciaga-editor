import SwiftUI
import AppKit

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    let language: Language
    let showLineNumbers: Bool
    let typewriterMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = CodeTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = Theme.editorFont
        textView.textColor = NSColor.balenciagaStrong
        textView.backgroundColor = NSColor.balenciagaPanel

        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticTextCompletionEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isFieldEditor = false

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.insertionPointColor = NSColor.balenciagaStrong
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.balenciagaAccent,
            .foregroundColor: NSColor.balenciagaStrong
        ]

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        applyEditorLayout(to: textView, in: scrollView)
        applyRulerIfNeeded(on: scrollView, textView: textView)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
        }
        if textView.selectedRange() != selection {
            textView.setSelectedRange(selection)
            textView.scrollRangeToVisible(selection)
        }

        applyEditorLayout(to: textView, in: nsView)
        applyRulerIfNeeded(on: nsView, textView: textView)
        context.coordinator.ensureFirstResponder(textView)
    }

    private func applyEditorLayout(to textView: NSTextView, in scrollView: NSScrollView) {
        let contentWidth = scrollView.contentSize.width
        if typewriterMode {
            let maxTextWidth: CGFloat = 760
            let horizontalInset = max((contentWidth - maxTextWidth) / 2.0, 20)
            textView.textContainerInset = NSSize(width: horizontalInset, height: 28)
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: maxTextWidth, height: CGFloat.greatestFiniteMagnitude)
        } else {
            textView.textContainerInset = NSSize(width: 16, height: 16)
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
    }

    private func applyRulerIfNeeded(on scrollView: NSScrollView, textView: NSTextView) {
        if showLineNumbers {
            if scrollView.verticalRulerView == nil {
                scrollView.verticalRulerView = LineNumberRulerView(textView: textView, scrollView: scrollView)
            }
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        } else {
            scrollView.hasVerticalRuler = false
            scrollView.rulersVisible = false
            scrollView.verticalRulerView = nil
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        private var hasFocusedOnce = false

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.selection = textView.selectedRange()
        }

        func ensureFirstResponder(_ textView: NSTextView) {
            guard !hasFocusedOnce else { return }
            guard let window = textView.window else { return }
            hasFocusedOnce = true
            window.makeFirstResponder(textView)
        }
    }
}

final class CodeTextView: NSTextView {
    override var acceptsFirstResponder: Bool { true }
}
