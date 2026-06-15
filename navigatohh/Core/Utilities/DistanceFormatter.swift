//
//  DistanceFormatter.swift
//  navigatohh
//
//  Shared formatting for distances in metres (e.g. "850 m", "1.2 km").
//

import Foundation

enum DistanceFormatter {
    static func string(meters: Double) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = meters >= 1000 ? 1 : 0
        return formatter.string(from: measurement)
    }
}
