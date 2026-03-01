import Foundation
import SwiftUI

public enum MatrixInlineMathTextStyle {
    case display
    case sectionTitle
    case body
    case bodyEmphasis
    case support
    case caption
    case footnote

    fileprivate var baseSize: CGFloat {
        switch self {
        case .display:
            return 34
        case .sectionTitle:
            return 17
        case .body:
            return 16
        case .bodyEmphasis:
            return 18
        case .support:
            return 15
        case .caption:
            return 12
        case .footnote:
            return 13
        }
    }

    fileprivate var weight: Font.Weight {
        switch self {
        case .display:
            return .bold
        case .sectionTitle:
            return .semibold
        case .body:
            return .regular
        case .bodyEmphasis:
            return .semibold
        case .support:
            return .regular
        case .caption:
            return .regular
        case .footnote:
            return .regular
        }
    }
}

public struct MatrixInlineMathText: View {
    public let text: String
    public var style: MatrixInlineMathTextStyle
    public var color: Color?
    public var accessibilityLabel: String?

    public init(
        _ text: String,
        style: MatrixInlineMathTextStyle = .body,
        color: Color? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.text = text
        self.style = style
        self.color = color
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        let rendered = Text(MatrixInlineMathFormatter.attributed(text, style: style))
        Group {
            if let color {
                rendered.foregroundStyle(color)
            } else {
                rendered
            }
        }
        .accessibilityLabel(accessibilityLabel ?? text)
    }
}

enum MatrixInlineMathFormatter {
    static func attributed(_ raw: String, style: MatrixInlineMathTextStyle) -> AttributedString {
        let normalized = normalize(raw)
        let baseSize = style.baseSize
        let scriptSize = max(10, baseSize * 0.76)
        let baseFont = Font.system(size: baseSize, weight: style.weight, design: .serif)
        let scriptFont = Font.system(size: scriptSize, weight: .regular, design: .serif)

        if !containsScriptSyntax(in: normalized) {
            var plain = AttributedString(normalized)
            plain.font = baseFont
            return plain
        }

        var output = AttributedString()
        var index = normalized.startIndex
        var plainBuffer = ""

        func flushPlainBuffer() {
            guard !plainBuffer.isEmpty else {
                return
            }
            var plain = AttributedString(plainBuffer)
            plain.font = baseFont
            output.append(plain)
            plainBuffer.removeAll(keepingCapacity: true)
        }

        while index < normalized.endIndex {
            let character = normalized[index]

            if character == "_" || character == "^" {
                let marker = character
                let nextIndex = normalized.index(after: index)
                if let script = parseScript(in: normalized, from: nextIndex) {
                    flushPlainBuffer()
                    let scriptContent = normalizeScript(script.content)
                    var scriptText = AttributedString(scriptContent)
                    scriptText.font = scriptFont
                    scriptText.baselineOffset = marker == "_" ? -(baseSize * 0.16) : (baseSize * 0.22)
                    output.append(scriptText)
                    index = script.nextIndex
                    continue
                }
            }

            plainBuffer.append(character)
            index = normalized.index(after: index)
        }

        flushPlainBuffer()
        return output
    }

    private static func containsScriptSyntax(in text: String) -> Bool {
        text.contains("_") || text.contains("^")
    }

    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "<-", with: "←")
            .replacingOccurrences(of: "->", with: "→")
    }

    private static func normalizeScript(_ script: String) -> String {
        script
            .replacingOccurrences(of: "beta", with: "β")
            .replacingOccurrences(of: "gamma", with: "γ")
    }

    private static func parseScript(
        in text: String,
        from start: String.Index
    ) -> (content: String, nextIndex: String.Index)? {
        guard start < text.endIndex else {
            return nil
        }

        if text[start] == "{" {
            return parseWrappedScript(in: text, from: start, open: "{", close: "}", includesWrapper: false)
        }

        if text[start] == "(" {
            return parseWrappedScript(in: text, from: start, open: "(", close: ")", includesWrapper: true)
        }

        var end = start
        while end < text.endIndex, isInlineScriptCharacter(text[end]) {
            end = text.index(after: end)
        }

        guard end > start else {
            return nil
        }

        return (String(text[start..<end]), end)
    }

    private static func parseWrappedScript(
        in text: String,
        from start: String.Index,
        open: Character,
        close: Character,
        includesWrapper: Bool
    ) -> (content: String, nextIndex: String.Index)? {
        var depth = 0
        var index = start

        while index < text.endIndex {
            let character = text[index]
            if character == open {
                depth += 1
            } else if character == close {
                depth -= 1
                if depth == 0 {
                    if includesWrapper {
                        return (String(text[start...index]), text.index(after: index))
                    }

                    let contentStart = text.index(after: start)
                    return (String(text[contentStart..<index]), text.index(after: index))
                }
            }
            index = text.index(after: index)
        }

        return nil
    }

    private static func isInlineScriptCharacter(_ character: Character) -> Bool {
        if character.isLetter || character.isNumber {
            return true
        }

        return character == "-" || character == "+" || character == "←" || character == "→"
    }
}
