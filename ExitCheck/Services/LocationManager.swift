import Foundation
import CoreLocation
import Combine
import SwiftUI

@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private var monitoredRegion: CLCircularRegion?

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isMonitoring = false
    @Published var lastExitTime: Date?
    @Published var locationError: String?

    var onExitRegion: (() -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    var hasAlwaysAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }

    var hasAnyAuthorization: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func requestCurrentLocation() {
        manager.requestLocation()
    }

    func startMonitoring(for homeLocation: HomeLocation) {
        guard hasAlwaysAuthorization else {
            locationError = "Always authorization required for geofencing"
            return
        }

        stopMonitoring()

        let region = homeLocation.region
        monitoredRegion = region

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            manager.startMonitoring(for: region)
            isMonitoring = true
            locationError = nil
            print("Started monitoring region: \(region.identifier)")
        } else {
            locationError = "Region monitoring not available on this device"
        }
    }

    func stopMonitoring() {
        if let region = monitoredRegion {
            manager.stopMonitoring(for: region)
            monitoredRegion = nil
            isMonitoring = false
            print("Stopped monitoring region")
        }
    }

    func checkCurrentRegionState() {
        guard let region = monitoredRegion else { return }
        manager.requestState(for: region)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            print("Authorization status changed: \(status.rawValue)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error.localizedDescription
            print("Location error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        Task { @MainActor in
            self.lastExitTime = Date()
            self.onExitRegion?()
            NotificationManager.shared.triggerExitNotification()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let stateDescription: String
        switch state {
        case .inside: stateDescription = "inside"
        case .outside: stateDescription = "outside"
        case .unknown: stateDescription = "unknown"
        }
        print("Region state: \(stateDescription) for \(region.identifier)")
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            self.locationError = "Monitoring failed: \(error.localizedDescription)"
            self.isMonitoring = false
        }
    }
}

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}
