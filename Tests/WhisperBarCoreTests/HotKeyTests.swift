import Carbon
import Foundation
import Testing
@testable import WhisperBarCore

@Suite("Hot keys")
struct HotKeyTests {
    @Test func defaultUsesControlOptionSpace() {
        let hotKey = HotKey.defaultToggle
        #expect(hotKey.keyCode == Int64(kVK_Space))
        #expect(hotKey.carbonModifiers & UInt32(controlKey) != 0)
        #expect(hotKey.carbonModifiers & UInt32(optionKey) != 0)
        #expect(hotKey.carbonModifiers & UInt32(cmdKey) == 0)
        #expect(hotKey.carbonModifiers & UInt32(shiftKey) == 0)
        #expect(hotKey.shiftSide == .any)
    }

    @Test func matchingUsesControlOptionSpace() {
        let hotKey = HotKey.defaultToggle
        #expect(hotKey.matches(keyCode: Int64(kVK_Space), carbonModifiers: UInt32(controlKey | optionKey), rightShift: false))
        #expect(!hotKey.matches(keyCode: Int64(kVK_Space), carbonModifiers: UInt32(cmdKey | optionKey), rightShift: false))
        #expect(!hotKey.matches(keyCode: Int64(kVK_ANSI_A), carbonModifiers: UInt32(controlKey | optionKey), rightShift: false))
    }

    @Test func displayNameIsReadable() {
        #expect(HotKey.defaultToggle.displayName == "Ctrl + Opt + Space")
    }

    @Test func storeDefaultsToUnset() {
        let suiteName = "HotKeyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = HotKeyStore(defaults: defaults)

        #expect(store.load() == nil)
        store.save(.defaultToggle)
        #expect(store.load() == .defaultToggle)
        store.clear()
        #expect(store.load() == nil)
    }

    @Test func legacyHelpMenuShortcutStillRequiresRightShift() {
        let hotKey = HotKey.legacyHelpMenuToggle
        #expect(hotKey.matches(keyCode: Int64(kVK_ANSI_Slash), carbonModifiers: UInt32(cmdKey | shiftKey), rightShift: true))
        #expect(!hotKey.matches(keyCode: Int64(kVK_ANSI_Slash), carbonModifiers: UInt32(cmdKey | shiftKey), rightShift: false))
    }
}
