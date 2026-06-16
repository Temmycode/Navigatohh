//
//  AppColors.swift
//  navigatohh
//
//  Centralised colour tokens. Brand palette is sky/turquoise blue on white/glass surfaces.
//  Prefer these over inline Color(...) values so theming stays consistent.
//

import SwiftUI

enum AppColors {
    // MARK: Brand (sky / turquoise blue)
    static let accent = Color(hex: "#0EA5E9")          // sky blue — primary actions
    static let accentSecondary = Color(hex: "#22D3EE") // turquoise / cyan — highlights
    static let accentDeep = Color(hex: "#0369A1")      // deep blue — contrast / gradient end
    static let onAccent = Color.white

    /// Brand gradient for primary buttons and accents.
    static let brandGradient = LinearGradient(
        colors: [accentSecondary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Neutrals
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let surface = Color(.tertiarySystemBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let separator = Color(.separator)
}
