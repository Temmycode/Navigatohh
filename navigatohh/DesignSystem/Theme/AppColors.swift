//
//  AppColors.swift
//  navigatohh
//
//  Centralised colour tokens. Prefer these over inline Color(...) values so theming stays
//  consistent and is easy to change in one place.
//

import SwiftUI

enum AppColors {
    static let accent = Color(hex: "#1B998B")
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let surface = Color(.tertiarySystemBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let separator = Color(.separator)
}
