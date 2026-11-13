//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import CoreLocation
import Foundation

/// Whether the app may read the device's location.
public enum CurrentLocationAuthorization: Equatable, Sendable {

    case notDetermined
    case allowed
    case denied
}

/// Why a location fix didn't arrive.
public enum CurrentLocationError: Error, Equatable, Sendable {

    case denied
    case unavailable
}

/// One location fix, through `CLLocationUpdate`'s async sequence.
///
/// The first call asks for permission. A refusal throws ``CurrentLocationError/denied``,
/// and no fix before the deadline ``CurrentLocationError/unavailable`` — so a
/// device with location services off can't hang the caller.
public struct CurrentLocation: Sendable {

    public init() {}

    public var authorization: CurrentLocationAuthorization {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .denied, .restricted:
            .denied
        default:
            .allowed
        }
    }

    /// The device's coordinate, or an error if there isn't one in time.
    public func locate(timeout: Duration = .seconds(15)) async throws -> CLLocationCoordinate2D {
        guard authorization != .denied else {
            throw CurrentLocationError.denied
        }

        do {
            return try await Timeout.run(for: timeout) {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDenied || update.authorizationDeniedGlobally {
                        throw CurrentLocationError.denied
                    }

                    if let location = update.location {
                        return location.coordinate
                    }
                }

                throw CurrentLocationError.unavailable
            }
        } catch is TimeoutError {
            throw CurrentLocationError.unavailable
        }
    }
}
