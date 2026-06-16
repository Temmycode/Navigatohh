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
    case bank
    case pharmacy
    case park
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
        case .bank:       return "Bank / ATM"
        case .pharmacy:   return "Pharmacy"
        case .park:       return "Park"
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
        case .bank:       return "banknote.fill"
        case .pharmacy:   return "pills.fill"
        case .park:       return "tree.fill"
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
        case .bank:       return .mint
        case .pharmacy:   return .cyan
        case .park:       return .green
        case .other:      return .gray
        }
    }

    /// Best-effort mapping from Mapbox POI `class` / `maki` strings (built-in POIs and
    /// geocoding results) to one of our categories. Defaults to `.other`.
    init(mapboxClass: String?, maki: String? = nil) {
        let value = (mapboxClass ?? maki ?? "").lowercased()
        switch value {
        case let v where v.contains("restaurant") || v.contains("food") || v.contains("cafe") || v.contains("bar") || v.contains("fast_food"):
            self = .restaurant
        case let v where v.contains("hospital") || v.contains("doctor") || v.contains("clinic") || v.contains("medical"):
            self = .hospital
        case let v where v.contains("pharmacy") || v.contains("chemist"):
            self = .pharmacy
        case let v where v.contains("school") || v.contains("college") || v.contains("university") || v.contains("education"):
            self = .school
        case let v where v.contains("bank") || v.contains("atm"):
            self = .bank
        case let v where v.contains("fuel") || v.contains("gas") || v.contains("petrol"):
            self = .fuel
        case let v where v.contains("hotel") || v.contains("lodging") || v.contains("motel") || v.contains("guest"):
            self = .hotel
        case let v where v.contains("market") || v.contains("grocery") || v.contains("supermarket") || v.contains("shop") || v.contains("store"):
            self = .market
        case let v where v.contains("worship") || v.contains("church") || v.contains("mosque") || v.contains("religious"):
            self = .worship
        case let v where v.contains("park") || v.contains("garden") || v.contains("playground"):
            self = .park
        case let v where v.contains("junction") || v.contains("roundabout") || v.contains("intersection"):
            self = .junction
        default:
            self = .other
        }
    }
}
