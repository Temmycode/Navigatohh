//
//  UUID+Deterministic.swift
//  navigatohh
//
//  Builds a stable UUID from a string seed so the same place (e.g. a tapped built-in POI or a
//  geocoding result identified by name+coordinate) always maps to the same id. This lets
//  favorites/recents dedupe places that don't come from the bundled dataset.
//

import Foundation
import CryptoKit

extension UUID {
    /// Deterministic UUID derived from a string seed (MD5 of the seed → 16 bytes).
    init(seed: String) {
        let digest = Insecure.MD5.hash(data: Data(seed.utf8))
        var bytes = [UInt8](digest)               // 16 bytes
        // Stamp version (5) and variant bits so it's a well-formed UUID.
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        self = UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
