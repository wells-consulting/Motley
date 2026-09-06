//
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Convenience extensions for reading common `Info.plist` values from the main bundle.
public extension Bundle {

    /// The executable name declared in `CFBundleExecutable` (e.g. `"MyApp"`).
    static let appName: String =
        (Bundle.main
            .infoDictionary?["CFBundleExecutable"] as? String) ?? "???"

    /// The bundle identifier declared in `CFBundleIdentifier` (e.g. `"com.example.MyApp"`).
    static let appBundleIdentifier: String =
        Bundle.main
        .bundleIdentifier ?? "???"

    /// The marketing version declared in `CFBundleShortVersionString` (e.g. `"1.0"`).
    static let appMarketingVersion: String =
        (Bundle.main
            .infoDictionary?["CFBundleShortVersionString"] as? String) ?? "???"

    /// The build number declared in `CFBundleVersion` (e.g. `"42"`).
    static let appBuildNumber: String =
        (Bundle.main
            .infoDictionary?["CFBundleVersion"] as? String) ?? "???"

    /// The marketing version combined with the build number (e.g. `"1.0.42"`).
    static var appSemanticVersion: String {
        "\(appMarketingVersion).\(appBuildNumber)"
    }

    /// The marketing version combined with the build number (e.g. `"1.0 (Build 42)"`).
    static var appAnnotatedVersion: String {
        "\(appMarketingVersion) (Build \(appBuildNumber))"
    }

    /// The filename of the app's primary icon, sourced from `CFBundleIcons`. Returns `nil`
    /// when no icon is configured or the `Info.plist` keys are absent.
    static var appIconFilename: String? {
        guard
            let icons = Bundle.main
                .object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let filename = iconFiles.last
        else {
            return nil
        }

        return filename
    }
}
