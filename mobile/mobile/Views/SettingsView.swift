//
//  SettingsView.swift
//  mobile
//
//  Created by Xiao Fei on 11/7/23.
//

import SwiftUI
import MapKit

struct SettingsView: View {
    
    @Binding var showSettings: Bool
    var latitude: Double
    var longitude: Double
    
//    let geofencePolygonCoordinates: [CLLocationCoordinate2D] = [
//            CLLocationCoordinate2D(latitude: 37.335034875313355, longitude: -122.06030576013998),
//            CLLocationCoordinate2D(latitude: 37.32956891898867, longitude: -122.06030576013998),
//            CLLocationCoordinate2D(latitude: 37.32956891898867, longitude: -122.04902156819315),
//            CLLocationCoordinate2D(latitude: 37.335034875313355, longitude: -122.04902156819315),
//            CLLocationCoordinate2D(latitude: 37.335034875313355, longitude: -122.06030576013998) // Close the polygon by repeating the first point
//        ]

    
    @State private var weatherAlerts = false
    
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Text("Settings")
            .padding(20)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        VStack(alignment: .center, spacing: 20) {
            Form {
                Section() {
                    Toggle(isOn: $weatherAlerts) {
                        Text("Weather Alerts")
                    }
                    
                    Toggle(isOn: $userSettings.isAirQualityNotificationEnabled) {
                        Text("Air Quality Notification")
                    }
                }
            }
//            FormButton(label: "Check Geofence", action: {
//                    let currentCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//                    if isCoordinate(currentCoordinate, insidePolygon: geofencePolygonCoordinates) {
//                        // Call the mutation query here if inside the geofence
//                        Task {
//                            await checkGeofenceAndSendMessage()
//                        }
//                        print("inside geofence.")
//                    }else {
//                        print("outside geofence")
//                    }
//                    showSettings.toggle()
//                })
            
            Spacer()
            FormButton(label: "Dismiss", action: {showSettings.toggle()})
        }
    }
}

//func isCoordinate(_ coordinate: CLLocationCoordinate2D, insidePolygon polygonCoordinates: [CLLocationCoordinate2D]) -> Bool {
//    let polygon = MKPolygon(coordinates: polygonCoordinates, count: polygonCoordinates.count)
//    let mapPoint = MKMapPoint(coordinate)
//
//    let polygonRenderer = MKPolygonRenderer(polygon: polygon)
//    let polygonViewPoint = polygonRenderer.point(for: mapPoint)
//    return polygonRenderer.path.contains(polygonViewPoint)
//}
//
//func checkGeofenceAndSendMessage() async {
//    do {
//        let timestamp = ISO8601DateFormatter().string(from: Date())
//        let result = try await DataService().createVehicleMessage(message: "Entered geofence.", owner: "Vehicle1", timestamp: timestamp)
//        print(result)
//    }catch {
//        print("Error fetching places: \(error)")
//    }
//}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
