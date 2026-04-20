import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var placeName: String?
    var isLoading = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return true
        default: return false
        }
    }

    func requestLocation() {
        guard isAuthorized else { return }
        isLoading = true
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            if let pm = placemarks?.first {
                let parts = [pm.locality, pm.administrativeArea].compactMap { $0 }
                self.placeName = parts.isEmpty ? nil : parts.joined(separator: ", ")
            }
            self.isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
    }
}
