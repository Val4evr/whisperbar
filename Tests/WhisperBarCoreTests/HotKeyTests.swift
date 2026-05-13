import Carbon
import Testing
@testable import WhisperBarCore

@Suite("Hot keys")
struct HotKeyTests {
    @Test func defaultUsesCommandRightShiftSlash() {
        let hotKey = HotKey.defaultToggle
        #expect(hotKey.keyCode == Int64(kVK_ANSI_Slash))
        #expect(hotKey.carbonModifiers & UInt32(cmdKey) != 0)
        #expect(hotKey.carbonModifiers & UInt32(shiftKey) != 0)
        #expect(hotKey.shiftSide == .right)
    }

    @Test func matchingHonorsRightShift() {
        let hotKey = HotKey.defaultToggle
        #expect(hotKey.matches(keyCode: Int64(kVK_ANSI_Slash), carbonModifiers: UInt32(cmdKey | shiftKey), rightShift: true))
        #expect(!hotKey.matches(keyCode: Int64(kVK_ANSI_Slash), carbonModifiers: UInt32(cmdKey | shiftKey), rightShift: false))
        #expect(!hotKey.matches(keyCode: Int64(kVK_ANSI_A), carbonModifiers: UInt32(cmdKey | shiftKey), rightShift: true))
    }

    @Test func displayNameIsReadable() {
        #expect(HotKey.defaultToggle.displayName == "Cmd + Right Shift + /")
    }
}
