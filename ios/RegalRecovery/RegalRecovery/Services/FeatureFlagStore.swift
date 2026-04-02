import Foundation
import SwiftUI

@Observable
final class FeatureFlagStore {
    static let shared = FeatureFlagStore()

    /// Incremented on every flag change to trigger SwiftUI updates
    private(set) var version: Int = 0

    private init() {}

    func isEnabled(_ key: String) -> Bool {
        // Touch version to create observation dependency
        _ = version
        return UserDefaults.standard.object(forKey: "ff.\(key)") as? Bool ?? true
    }

    func setFlag(_ key: String, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "ff.\(key)")
        version += 1
    }

    /// Call after bulk flag operations (Enable All, Disable All, Reset)
    func flagsDidChange() {
        version += 1
    }
}
