import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    
    // Make Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Create MKMapView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.userTrackingMode = .follow // Follow user location
        return mapView
    }
    
    // Update the view as the user's location changes
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(overlays)
    }
    
    // Coordinator to act as MKMapViewDelegate
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// Extension for the convenience initializer
extension MKPolygon {
    convenience init(coordinates: [CLLocationCoordinate2D]) {
        self.init(coordinates: coordinates, count: coordinates.count)
    }
}

// the main iOS view that displays the Map, the user's current location and action buttons
struct MapView: View {
    
    // subscribe to vehicle messages from the Cloud
    @ObservedObject var vehicleMessageService = VehicleMessageService()
    
    // subscribe to the user's current location
    @ObservedObject var locationService = LocationService()
    
    // set the initial map region
    //@State private var region = MKCoordinateRegion()
    
    // state variables to control the visibility of modal sheets
    @State private var showWeatherView = false
    @State private var showPOIView = false
    @State private var showMessagesView = false
    @State private var showSettingsView = false
    @State private var userIsInGeofence: Bool = false
    
    let geofencePolygonCoordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.335034875313355, longitude: -122.06030576013998),
            CLLocationCoordinate2D(latitude: 37.32956891898867, longitude: -122.06030576013998),
            CLLocationCoordinate2D(latitude: 37.32956891898867, longitude: -122.04902156819315),
            CLLocationCoordinate2D(latitude: 37.335034875313355, longitude: -122.04902156819315),
            CLLocationCoordinate2D(latitude: 37.335034875313355, longitude: -122.06030576013998) // Close the polygon by repeating the first point
        ]
    
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
    var geofenceOverlay: MKPolygon {
        MKPolygon(coordinates: geofencePolygonCoordinates)
    }
    
    var body: some View {
        ZStack {
//            Map (
//                coordinateRegion: $region,
//                showsUserLocation: true,
//                userTrackingMode: .constant(.follow)
//            ).edgesIgnoringSafeArea(.all)
            MapViewRepresentable(region: $region, overlays: [geofenceOverlay])
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Set the initial region based on the current location on appear, if desired
                    if let currentLocation = locationService.lastLocation {
                        region.center = currentLocation.coordinate
                    }
                }
                .onReceive(locationService.$lastLocation) { newLocation in
                    // When location updates, update the map region
                    if let newLocation = newLocation {
                        //region.center = newLocation.coordinate
                        
                        // Perform geofence check and update the userIsInGeofence state
                        userIsInGeofence = isCoordinate(newLocation.coordinate, insidePolygon: geofencePolygonCoordinates)
                    }
                }
                .onChange(of: userIsInGeofence) { isInGeofence in
                    // Respond to changes in geofence status
                    if isInGeofence {
                        // If the user has entered the geofence, perform the necessary actions
                        Task {
                            await checkGeofenceAndSendMessage()
                        }
                        print("sending message...")
                    }else {
                        print("not in geofence")
                    }
                }
            VStack {
                Spacer()
                Text(locationService.city)
                    .font(.title)
                    .padding(.bottom, 20)
                HStack {
                    MapButton(image: "cloud.fill", action: {showWeatherView.toggle()})
                        .sheet(isPresented: $showWeatherView) {
                            WeatherView(
                                showView: $showWeatherView,
                                latitude: locationService.latitude,
                                longitude: locationService.longitude,
                                city: locationService.city
                            )
                        }
                    MapButton(image: "mappin.circle", action: {showPOIView.toggle()})
                        .sheet(isPresented: $showPOIView) {
                            PlacesView(
                                showView: $showPOIView,
                                latitude: locationService.latitude,
                                longitude: locationService.longitude
                            )
                        }
                    MapButton(image: "text.bubble", action: {showMessagesView.toggle()})
                    .sheet(isPresented: $showMessagesView) {
                        MessagesView(
                            showView: $showMessagesView,
                            messages: $vehicleMessageService.messages
                        )
                    }
                    MapButton(image: "gear", action: {showSettingsView.toggle()})
                        .sheet(isPresented: $showSettingsView) {
                            SettingsView(
                                showSettings: $showSettingsView,
                                latitude: locationService.latitude,
                                longitude: locationService.longitude
                            )
                        }
                }
            }
        }
        .onDisappear {
            vehicleMessageService.cancelSubscription()
        }
    }
}

func isCoordinate(_ coordinate: CLLocationCoordinate2D, insidePolygon polygonCoordinates: [CLLocationCoordinate2D]) -> Bool {
    let polygon = MKPolygon(coordinates: polygonCoordinates, count: polygonCoordinates.count)
    let mapPoint = MKMapPoint(coordinate)
    
    let polygonRenderer = MKPolygonRenderer(polygon: polygon)
    let polygonViewPoint = polygonRenderer.point(for: mapPoint)
    return polygonRenderer.path.contains(polygonViewPoint)
}

func checkGeofenceAndSendMessage() async {
    do {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let result = try await DataService().createVehicleMessage(message: "Entered geofence.", owner: "Vehicle1", timestamp: timestamp)
        print(result)
    }catch {
        print("Error fetching places: \(error)")
    }
}

//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView()
//    }
//}
