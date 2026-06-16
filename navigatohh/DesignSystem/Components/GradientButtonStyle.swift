//
//  GradientButtonStyle.swift
//  navigatohh
//
//  Primary call-to-action button: a blue→turquoise gradient pill with white text.
//

import SwiftUI

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundStyle(AppColors.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.brandGradient, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GradientButtonStyle {
    static var gradient: GradientButtonStyle { GradientButtonStyle() }
}
