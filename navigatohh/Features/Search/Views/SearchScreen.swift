//
//  SearchScreen.swift
//  navigatohh
//
//  Searchable list of POIs with a category filter. Selecting a result opens it on the map.
//

import SwiftUI

struct SearchScreen: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.router) private var router
    @State private var viewModel: SearchViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Search")
        .task {
            guard viewModel == nil else { return }
            let vm = SearchViewModel(repository: dependencies.placesRepository)
            viewModel = vm
            await vm.loadInitial()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: SearchViewModel) -> some View {
        @Bindable var viewModel = viewModel

        List {
            Section {
                categoryFilter(viewModel)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if viewModel.results.isEmpty {
                ContentUnavailableView.search
            } else {
                ForEach(viewModel.results) { place in
                    Button {
                        router.showPlace(place.id)
                    } label: {
                        placeRow(place)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.query, prompt: "Search Bashorun/Bodija")
    }

    private func categoryFilter(_ viewModel: SearchViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(PlaceCategory.allCases) { category in
                    FilterChip(
                        title: category.title,
                        systemImage: category.symbolName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private func placeRow(_ place: PointOfInterest) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: place.category.symbolName)
                .foregroundStyle(place.category.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(AppTypography.headline)
                if let address = place.address {
                    Text(address)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

private struct FilterChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(AppTypography.caption)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                isSelected ? AppColors.accent : AppColors.secondaryBackground,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : AppColors.primaryText)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SearchScreen()
            .environment(\.dependencies, AppDependencies())
            .environment(\.router, AppRouter())
    }
}
