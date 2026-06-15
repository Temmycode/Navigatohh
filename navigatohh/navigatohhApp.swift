//
//  navigatohhApp.swift
//  navigatohh
//
//  Created by Temiloluwa Akisanya on 14/06/2026.
//

import SwiftUI

@main
struct navigatohhApp: App {
    @State private var dependencies = AppDependencies()
    @State private var router = AppRouter()

    init() {
        MapboxConfigurator.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dependencies, dependencies)
                .environment(\.router, router)
        }
    }
}
