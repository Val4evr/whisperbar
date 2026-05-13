import Carbon
import Foundation

public enum KeyboardSide: String, Codable, Sendable, Equatable {
    case any
    case left
    case right
}

public struct HotKey: Codable, Equatable, Sendable {
    public var keyCode: Int64
    public var carbonModifiers: UInt32
    public var shiftSide: KeyboardSide

    public init(keyCode: Int64, carbonModifiers: UInt32, shiftSide: KeyboardSide) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.shiftSide = shiftSide
    }

    public static let defaultToggle = HotKey(
        keyCode: Int64(kVK_Space),
        carbonModifiers: UInt32(controlKey | optionKey),
        shiftSide: .any
    )

    public static let legacyHelpMenuToggle = HotKey(
        keyCode: Int64(kVK_ANSI_Slash),
        carbonModifiers: UInt32(cmdKey | shiftKey),
        shiftSide: .right
    )

    public var displayName: String {
        var pieces: [String] = []
        if carbonModifiers & UInt32(cmdKey) != 0 { pieces.append("Cmd") }
        if carbonModifiers & UInt32(optionKey) != 0 { pieces.append("Opt") }
        if carbonModifiers & UInt32(controlKey) != 0 { pieces.append("Ctrl") }
        if carbonModifiers & UInt32(shiftKey) != 0 {
            pieces.append(shiftSide == .right ? "Right Shift" : "Shift")
        }
        pieces.append(Self.keyName(for: keyCode))
        return pieces.joined(separator: " + ")
    }

    public func matches(keyCode: Int64, carbonModifiers: UInt32, rightShift: Bool) -> Bool {
        guard self.keyCode == keyCode else { return false }
        let relevantMask = UInt32(cmdKey | optionKey | controlKey | shiftKey)
        guard carbonModifiers & relevantMask == self.carbonModifiers & relevantMask else { return false }
        if shiftSide == .right {
            return rightShift
        }
        return true
    }

    private static func keyName(for keyCode: Int64) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_Slash: return "/"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Escape: return "Esc"
        default: return "Key \(keyCode)"
        }
    }
}
