import SwiftUI

public enum MatrixUIDesignTokens {
    public enum Spacing {
        public static let compact: CGFloat = 6
        public static let regular: CGFloat = 12
        public static let comfortable: CGFloat = 18
    }

    public enum CornerRadius {
        public static let card: CGFloat = 12
        public static let control: CGFloat = 8
    }

    public enum Typography {
        public static let sectionTitle: Font = .headline
        public static let supportText: Font = .subheadline
    }

    public enum ColorPalette {
        public static var cardBackground: Color {
            #if os(iOS) || os(tvOS) || os(visionOS)
            return Color(uiColor: .secondarySystemBackground)
            #elseif os(macOS)
            return Color(nsColor: .windowBackgroundColor)
            #else
            return Color.gray.opacity(0.12)
            #endif
        }

        public static var controlBackground: Color {
            #if os(iOS) || os(tvOS) || os(visionOS)
            return Color(uiColor: .tertiarySystemBackground)
            #elseif os(macOS)
            return Color(nsColor: .controlBackgroundColor)
            #else
            return Color.gray.opacity(0.2)
            #endif
        }
    }
}
