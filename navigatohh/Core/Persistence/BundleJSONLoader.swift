//
//  BundleJSONLoader.swift
//  navigatohh
//
//  Small helper for decoding JSON resources shipped in the app bundle.
//

import Foundation

enum BundleJSONLoaderError: LocalizedError {
    case resourceNotFound(name: String, ext: String)

    var errorDescription: String? {
        switch self {
        case let .resourceNotFound(name, ext):
            return "Could not find \(name).\(ext) in the app bundle."
        }
    }
}

enum BundleJSONLoader {
    /// Decodes a bundled JSON file into the requested `Decodable` type.
    nonisolated static func load<T: Decodable>(
        _ type: T.Type = T.self,
        from name: String,
        withExtension ext: String = "json",
        bundle: Bundle = .main,
        decoder: JSONDecoder = .init()
    ) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw BundleJSONLoaderError.resourceNotFound(name: name, ext: ext)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}
