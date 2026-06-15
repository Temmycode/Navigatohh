//
//  RemoteImage.swift
//  navigatohh
//
//  Thin wrapper over Kingfisher's KFImage so the rest of the app loads remote images through
//  one consistent component (placeholder, fade-in, caching) and isn't coupled to Kingfisher's
//  API directly.
//

import SwiftUI
import Kingfisher

struct RemoteImage: View {
    let url: URL?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        KFImage(url)
            .placeholder { placeholder }
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .clipped()
    }

    private var placeholder: some View {
        ZStack {
            AppColors.secondaryBackground
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}
