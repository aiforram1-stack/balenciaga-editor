import AppKit

final class LineNumberRulerView: NSRulerView {
    private let textView: NSTextView
    private let font: NSFont = NSFont.systemFont(ofSize: 11, weight: .bold)

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 52
        self.needsDisplay = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textDidChange() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager else { return }

        let visibleRect = textView.enclosingScrollView?.contentView.bounds ?? .zero
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let textNSString = textView.string as NSString

        var lineNumber = lineNumberForCharacterIndex(charRange.location, in: textNSString)
        var glyphIndex = glyphRange.location

        while glyphIndex < NSMaxRange(glyphRange) {
            var lineRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)

            let y = lineRect.minY + textView.textContainerInset.height
            let label = "\(lineNumber)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.balenciagaMuted
            ]
            let x = ruleThickness - label.size(withAttributes: attributes).width - 8
            label.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)

            glyphIndex = NSMaxRange(lineRange)
            lineNumber += 1
        }
    }

    private func lineNumberForCharacterIndex(_ index: Int, in text: NSString) -> Int {
        if index <= 0 { return 1 }
        var line = 1
        var i = 0
        while i < index && i < text.length {
            if text.character(at: i) == 10 { line += 1 }
            i += 1
        }
        return line
    }
}
