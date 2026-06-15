//
//  LoadingView.swift
//  navigatohh
//
//  Standard full-area loading indicator.
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text(message)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
