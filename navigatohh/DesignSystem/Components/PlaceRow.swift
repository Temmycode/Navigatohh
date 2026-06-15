//
//  PlaceRow.swift
//  navigatohh
//
//  Reusable list row for a point of interest (category icon, name, address, chevron).
//

import SwiftUI

struct PlaceRow: View {
    let place: PointOfInterest
    /// Optional trailing detail (e.g. distance "1.2 km").
    var trailingText: String?

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: place.category.symbolName)
                .foregroundStyle(place.category.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primaryText)
                if let address = place.address {
                    Text(address)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .monospacedDigit()
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.vertical, AppSpacing.xs)
        .contentShape(Rectangle())
    }
}
