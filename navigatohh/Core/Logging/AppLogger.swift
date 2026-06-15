//
//  AppLogger.swift
//  navigatohh
//
//  Thin wrapper over os.Logger with pre-defined subsystem/categories so logging is
//  consistent and filterable in Console.app / Instruments.
//
//  The loggers are `nonisolated` so they can be used from any isolation context
//  (e.g. CoreLocation delegate callbacks).
//

import Foundation
import OSLog

enum AppLogger {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "com.tolutech.navigatohh"

    nonisolated static let app      = Logger(subsystem: subsystem, category: "app")
    nonisolated static let map      = Logger(subsystem: subsystem, category: "map")
    nonisolated static let location = Logger(subsystem: subsystem, category: "location")
    nonisolated static let data     = Logger(subsystem: subsystem, category: "data")
    nonisolated static let network  = Logger(subsystem: subsystem, category: "network")
}
