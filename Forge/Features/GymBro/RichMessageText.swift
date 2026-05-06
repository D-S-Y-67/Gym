import SwiftUI
import MarkdownUI
import LaTeXSwiftUI

/// Renders an assistant message as mixed markdown + LaTeX.
///
/// Strategy: split the content on `$$…$$` display-math fences. Prose chunks
/// go through MarkdownUI (full block + inline markdown — headers, lists,
/// bold, code blocks, tables). Math chunks render via `LaTeX` from
/// LaTeXSwiftUI (MathJax-backed SVG with proper math typesetting).
///
/// Inline `$x^2$` math is left embedded in the prose. MarkdownUI will pass
/// `$` characters through as plain text, which is acceptable for v1 — the
/// assistant prompt prefers display math anyway. If we want true inline
/// math later, we'd need to wrap each prose paragraph in a `LaTeX(…)`
/// view in inline mode and lose the block markdown.
///
/// Robust to streaming: while the closing `$$` hasn't arrived yet, the
/// regex finds no match and the whole content renders as markdown. Once
/// the fence completes, the math segment swaps in.
struct RichMessageText: View {

    let content: String

    private static let displayMathPattern = /\$\$([\s\S]+?)\$\$/

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                segmentView(segment)
            }
        }
    }

    @ViewBuilder
    private func segmentView(_ segment: Segment) -> some View {
        switch segment {
        case .markdown(let text):
            Markdown(text)
                .markdownTheme(.gymBro)
                .textSelection(.enabled)
        case .displayMath(let tex):
            LaTeX(tex)
                .parsingMode(.all)
                .blockMode(.alwaysBlock)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    private var segments: [Segment] {
        Self.parse(content)
    }

    enum Segment: Equatable {
        case markdown(String)
        case displayMath(String)
    }

    static func parse(_ text: String) -> [Segment] {
        var segments: [Segment] = []
        var cursor = text.startIndex

        while cursor < text.endIndex {
            let remainder = text[cursor...]
            guard let match = remainder.firstMatch(of: displayMathPattern) else {
                let tail = String(remainder)
                if !tail.isEmpty {
                    segments.append(.markdown(tail))
                }
                break
            }

            let prefix = String(remainder[remainder.startIndex..<match.range.lowerBound])
            if !prefix.isEmpty {
                segments.append(.markdown(prefix))
            }

            let tex = String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)
            if !tex.isEmpty {
                segments.append(.displayMath(tex))
            }

            cursor = match.range.upperBound
        }

        if segments.isEmpty {
            return [.markdown(text)]
        }
        return segments
    }
}

// MARK: - Theme

private extension MarkdownUI.Theme {

    /// Theme tuned for the assistant bubble. Picks up `.primary` text color
    /// from the surrounding bubble's `foregroundStyle` and uses a code-block
    /// surface that contrasts inside `.secondarySystemBackground`.
    static let gymBro = MarkdownUI.Theme()
        .text {
            ForegroundColor(.primary)
            FontSize(.em(1.0))
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.92))
            BackgroundColor(.tertiarySystemFill)
        }
        .codeBlock { config in
            ScrollView(.horizontal, showsIndicators: false) {
                config.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.20))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.88))
                    }
                    .padding(Theme.Spacing.sm + 2)
            }
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        }
        .heading1 { config in
            config.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.30))
                }
                .padding(.top, Theme.Spacing.xs)
        }
        .heading2 { config in
            config.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.18))
                }
                .padding(.top, Theme.Spacing.xs)
        }
        .heading3 { config in
            config.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.06))
                }
        }
        .blockquote { config in
            config.label
                .padding(.leading, Theme.Spacing.sm)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 3)
                }
                .foregroundStyle(.secondary)
        }
        .link {
            ForegroundColor(.accentColor)
            UnderlineStyle(.single)
        }
}

private extension Color {
    static var tertiarySystemFill: Color {
        Color(uiColor: .tertiarySystemFill)
    }
}

#Preview("Markdown + math") {
    ScrollView {
        RichMessageText(content: """
        ## Deload protocol

        - **Volume:** drop to 50–60% of normal
        - **Intensity:** ~70% of working weights
        - Keep technique sharp

        Estimated 1RM via Epley:

        $$1RM = w \\times (1 + r/30)$$

        Then resume the next block fresh.
        """)
        .padding()
    }
}
