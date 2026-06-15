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
            let vm = SearchViewModel(
                repository: dependencies.placesRepository,
                locationService: dependencies.locationService
            )
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

            if viewModel.displayResults.isEmpty {
                ContentUnavailableView.search
            } else {
                Section {
                    ForEach(viewModel.displayResults) { place in
                        Button {
                            router.showPlace(place.id)
                        } label: {
                            PlaceRow(place: place, trailingText: viewModel.distanceText(for: place))
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    if viewModel.isShowingNearby {
                        Label("Nearby", systemImage: "location.fill")
                            .font(AppTypography.caption)
                            .textCase(nil)
                    }
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
