import Foundation
import SwiftData
import CoreLocation

@Model
final class HomeLocation {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var radius: Double
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(
        latitude: Double,
        longitude: Double,
        radius: Double = 100,
        name: String = "Home"
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var region: CLCircularRegion {
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: "home_geofence_\(id.uuidString)"
        )
        region.notifyOnExit = true
        region.notifyOnEntry = false
        return region
    }

    func update(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.updatedAt = Date()
    }

    func update(radius: Double) {
        self.radius = max(50, min(radius, 500))
        self.updatedAt = Date()
    }
}
