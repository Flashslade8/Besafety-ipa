import SwiftUI
import CoreLocation
import MapKit

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last?.coordinate
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -26.2041, longitude: 28.0473), // Johannesburg
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var status = "No request yet"

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(status)
                    .font(.subheadline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)

                Button {
                    status = "Searching for available chaperones…"
                } label: {
                    Text("I NEED A CHAPERONE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .onAppear { locationManager.request() }
        .onReceive(locationManager.$location) { coord in
            if let coord { region.center = coord }
        }
    }
}
