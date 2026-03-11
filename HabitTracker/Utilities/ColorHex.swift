import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Creates a Color from a hex string (e.g. "#FF5733" or "FF5733").
    init?(hex: String?) {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hex.isEmpty else { return nil }
        var hexSanitized = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if hexSanitized.count == 6 {
            hexSanitized += "FF"
        }
        guard hexSanitized.count == 8,
              let value = UInt64(hexSanitized, radix: 16) else { return nil }
        let r = Double((value >> 24) & 0xFF) / 255
        let g = Double((value >> 16) & 0xFF) / 255
        let b = Double((value >> 8) & 0xFF) / 255
        let a = Double(value & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Returns a hex string (e.g. "FF5733") without alpha for persistence.
    func toHex() -> String? {
        #if canImport(UIKit)
        let cg = UIColor(self).cgColor
        #elseif canImport(AppKit)
        let cg = NSColor(self).cgColor
        #else
        return nil
        #endif
        guard let components = cg.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
