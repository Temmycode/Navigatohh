//
//  GlassCard.swift
//  navigatohh
//
//  Frosted-glass container styling used across overlays (map sheet, banners, controls).
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.lg
    var strokeOpacity: Double = 0.18

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
    }
}

extension View {
    /// Wraps the view in a frosted-glass card with a hairline highlight and soft shadow.
    func glassCard(cornerRadius: CGFloat = AppRadius.lg, strokeOpacity: Double = 0.18) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }
}
