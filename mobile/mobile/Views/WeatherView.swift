import SwiftUI

// sheet view that displays the weather based on the user's current location
struct WeatherView: View {
    
    @Binding var showView: Bool
    
    var latitude: Double
    var longitude: Double
    var city: String
    
    @State var aqIndex: Double = 0
    @State var temperature: Double = 0
    @State var isFetching: Bool = true
    @State private var showAlert = false
    
    @EnvironmentObject var userSettings: UserSettings
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    var body: some View {
        Text("Weather")
            .padding(20)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
        VStack(alignment: .center, spacing: 20) {
            if (isFetching) {
                LoadingView(label: "Determining the weather")
            } else {
                Text(city)
                    .font(.largeTitle)
                    .padding(.top, 75)
                Text("Temperature")
                    .font(.title)
                    .padding(.top, 50)
                Text(String(temperature))
                    .font(.title)
                Text("Air Quality Index")
                    .font(.title)
                    .padding(.top, 10)
                Text(String(aqIndex))
                    .font(.title)
            }
            Spacer()
            FormButton(label: "Dismiss", action: {showView.toggle()})
        }
        .onAppear {
            Task {
                await fetch()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // function to call the Data Service and retrieve the weather for the user's current location
    func fetch() async {
        
        isFetching = true
        
        do {
            let result = try await DataService().getWeather(latitude: latitude, longitude: longitude)
            aqIndex = result.aqIndex
            temperature = result.temperature
            
            // Trigger the alert if the AQI is over 20
//            if aqIndex > 10 && userSettings.isAirQualityNotificationEnabled {
//                showAlert = true
//            }
            
            // Check the AQI and decide if we should show an alert
            if userSettings.isAirQualityNotificationEnabled {
                switch aqIndex {
                    case 0...50:
                        showAlert(with: "Good Air Quality",
                                  message: "Air quality is considered satisfactory, and air pollution poses little or no risk.")
                    case 51...100:
                        showAlert(with: "Moderate Air Quality",
                                  message: "Air quality is acceptable; however, for some pollutants there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution.")
                    case 101...150:
                        showAlert(with: "Unhealthy for Sensitive Groups",
                                  message: "People with respiratory or heart conditions, the elderly and children should limit prolonged outdoor exertion.")
                    case 151...200:
                        showAlert(with: "Unhealthy",
                                  message: "Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects.")
                    case 201...300:
                        showAlert(with: "Very Unhealthy",
                                  message: "Health warnings of emergency conditions. The entire population is more likely to be affected.")
                    case let aqi where aqi > 300:
                        showAlert(with: "Hazardous",
                                  message: "Health alert: everyone may experience more serious health effects.")
                    default:
                        break
                }
            }
        } catch {
            print("Error fetching weather: \(error)")
        }

        isFetching = false
    }
    
    private func showAlert(with title: String, message: String) {
        DispatchQueue.main.async {
            self.showAlert = true
            self.alertTitle = title
            self.alertMessage = message
        }
    }
}

