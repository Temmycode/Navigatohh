//
//  PlaceCategory.swift
//  navigatohh
//
//  Categories used to classify points of interest around Bashorun/Bodija.
//

import SwiftUI

enum PlaceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case landmark
    case market
    case junction
    case restaurant
    case hotel
    case school
    case hospital
    case worship
    case fuel
    case other

    var id: String { rawValue }

    /// Human-readable label for UI.
    var title: String {
        switch self {
        case .landmark:   return "Landmark"
        case .market:     return "Market"
        case .junction:   return "Junction"
        case .restaurant: return "Restaurant"
        case .hotel:      return "Hotel"
        case .school:     return "School"
        case .hospital:   return "Hospital"
        case .worship:    return "Place of Worship"
        case .fuel:       return "Fuel Station"
        case .other:      return "Other"
        }
    }

    /// SF Symbol used for map annotations and list rows.
    var symbolName: String {
        switch self {
        case .landmark:   return "mappin.and.ellipse"
        case .market:     return "cart.fill"
        case .junction:   return "arrow.triangle.branch"
        case .restaurant: return "fork.knife"
        case .hotel:      return "bed.double.fill"
        case .school:     return "graduationcap.fill"
        case .hospital:   return "cross.case.fill"
        case .worship:    return "building.columns.fill"
        case .fuel:       return "fuelpump.fill"
        case .other:      return "mappin"
        }
    }

    var tint: Color {
        switch self {
        case .landmark:   return .orange
        case .market:     return .green
        case .junction:   return .blue
        case .restaurant: return .red
        case .hotel:      return .purple
        case .school:     return .indigo
        case .hospital:   return .pink
        case .worship:    return .teal
        case .fuel:       return .yellow
        case .other:      return .gray
        }
    }
}
