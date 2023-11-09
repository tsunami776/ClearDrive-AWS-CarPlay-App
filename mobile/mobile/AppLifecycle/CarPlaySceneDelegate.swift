import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var carWindow: CPWindow?
    var interfaceController: CPInterfaceController?
    
    // services to receive location and messages
    var locationService: LocationService?
    var vehicleMessageService: VehicleMessageService?
    
    // templates for each screen type
    var mapTemplate: CPMapTemplate?
    var coffeeTemplate: CPListTemplate?
    var fuelTemplate: CPListTemplate?
    var foodTemplate: CPListTemplate?
    var weatherTemplate: CPInformationTemplate?
    
    var vehicleMessageDisplayed = false
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        
        print("Connected to CarPlay.")
        
        self.interfaceController = interfaceController
        self.carWindow = window

        // initialize the templates that display each screen
        initTemplates()
        
        window.rootViewController = CarPlayMapView()
        interfaceController.setRootTemplate(mapTemplate!, animated: true, completion: nil)

        // initiate the services that provide data
        self.locationService = LocationService()
        self.locationService?.delegate = self
        
        self.vehicleMessageService = VehicleMessageService()
        self.vehicleMessageService?.delegate = self
    }
    
    func getMapBarButtons() -> [CPBarButton] {
        
        // buttons for Weather and Places in the app main navbar
        var buttons: [CPBarButton] = [CPBarButton]()
        
        buttons.append(CPBarButton(image: UIImage(systemName: "mappin.circle.fill")!, handler: { item in
            print("places clicked")
            self.interfaceController?.pushTemplate(self.getPlacesGridTemplate(), animated: true, completion: nil)
        }))

        buttons.append(CPBarButton(image: UIImage(systemName: "cloud.fill")!, handler: { item in
            print("weather clicked")
            self.interfaceController?.pushTemplate(self.weatherTemplate!, animated: true, completion: nil)
        }))
        
        return buttons
    }
    
    func getPlacesGridTemplate() -> CPGridTemplate {
        
        // buttons and actions displayed when user selects the Places icon in the main navbar
        var gridButtons: [CPGridButton] = [CPGridButton]()
        
        gridButtons.append(CPGridButton(titleVariants: ["Coffee"], image: UIImage(named: "poi", in: Bundle.main, compatibleWith: self.carWindow?.rootViewController?.traitCollection)!, handler: { item in
            self.interfaceController?.pushTemplate(self.coffeeTemplate!, animated: true, completion: nil)
        }))
        
        gridButtons.append(CPGridButton(titleVariants: ["Food"], image: UIImage(named: "poi", in: Bundle.main, compatibleWith: self.carWindow?.rootViewController?.traitCollection)!, handler: { item in
            self.interfaceController?.pushTemplate(self.foodTemplate!, animated: true, completion: nil)
        }))
        
        gridButtons.append(CPGridButton(titleVariants: ["Fuel"], image: UIImage(named: "poi", in: Bundle.main, compatibleWith: self.carWindow?.rootViewController?.traitCollection)!, handler: { item in
            self.interfaceController?.pushTemplate(self.fuelTemplate!, animated: true, completion: nil)
        }))
        
        return CPGridTemplate(title: "Places", gridButtons: gridButtons)
    }
    
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {

        print("Disconnected from CarPlay.")
        self.vehicleMessageService?.cancelSubscription()
        self.interfaceController = nil
    }
    
    func initTemplates() {
        
        // initialize the templates with their title and empty data
        self.mapTemplate = CPMapTemplate()
        self.mapTemplate?.trailingNavigationBarButtons.append(contentsOf: getMapBarButtons())
        
        self.coffeeTemplate = CPListTemplate(title: "Coffee", sections: [CPListSection(items: [])])
        
        self.fuelTemplate = CPListTemplate(title: "Fuel", sections: [CPListSection(items: [])])
        
        self.foodTemplate = CPListTemplate(title: "Food", sections: [CPListSection(items: [])])
        
        self.weatherTemplate = CPInformationTemplate(title: "Weather", layout: CPInformationTemplateLayout.twoColumn, items: [], actions: [])
        
    }
    
    func getPlaces (template: CPListTemplate, latitude: Double, longitude: Double, placeType: PlaceType) async {
        
        // call the Data Service to retrieve the requested PlaceTypes for the user's current location
        // and update the provided places template
        
        var listItems: [CPListItem] = [CPListItem]()
        
        Task {
            // call the Data Service to retrieve the weather for the user's current location and update the weatherTemplate
            do {
                let places = try await DataService().getPlaces(placeType: placeType, latitude: latitude, longitude: longitude, maxResults: 3)
                
                for place in places {
                    let item = CPListItem(text: place.name, detailText: place.address)

                    item.handler = { item, completion in
                        self.interfaceController?.popToRootTemplate(animated: true) {_, _ in

                            // display an alert to select this destination
                            // future functionality would be to initiate navigation directions
                            let alert = CPNavigationAlert(
                                titleVariants: [place.name],
                                subtitleVariants: [place.address],
                                image: nil,
                                primaryAction: CPAlertAction(title: "Go", style: CPAlertAction.Style.default, handler: {_ in }),
                                secondaryAction: nil,
                                duration: TimeInterval(20))

                            self.mapTemplate?.present(navigationAlert: alert, animated: true)
                        }
                    }

                    listItems.append(item)
                }
                
                template.updateSections([CPListSection(items: listItems)])
            } catch {
                print("Error fetching places: \(error)")
            }
        }
    }
    
    func presentAQIAlert(aqi: Int) {
        let title: String
        let message: String
        
        switch aqi {
        case 0...50:
            title = "Good AQI"
            message = "Air quality is considered satisfactory, and air pollution poses little or no risk."
        case 51...100:
            title = "Moderate AQI"
            message = "Air quality is acceptable; however, there may be a risk for some people, particularly those who are unusually sensitive to air pollution."
        case 101...150:
            title = "Unhealthy for Sensitive Groups"
            message = "Members of sensitive groups may experience health effects. The general public is not likely to be affected."
        case 151...200:
            title = "Unhealthy AQI"
            message = "Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects."
        case 201...300:
            title = "Very Unhealthy AQI"
            message = "Health alert: everyone may experience more serious health effects."
        case 301...:
            title = "Hazardous AQI"
            message = "Health warnings of emergency conditions. The entire population is more likely to be affected."
        default:
            return // No alert for invalid values
        }
        
        let okAction = CPAlertAction(title: "OK", style: .default, handler: { _ in
            self.interfaceController?.dismissTemplate(animated: true, completion: nil)
        })
            
        // Note that the `titleVariants` now includes both the title and message
        let alertTemplate = CPAlertTemplate(titleVariants: [title, message], actions: [okAction])
        
        self.interfaceController?.presentTemplate(alertTemplate, animated: true, completion: nil)
    }
    
    func getWeather (template: CPInformationTemplate, latitude: Double, longitude: Double, city: String) async {
        
        Task {
            // call the Data Service to retrieve the weather for the user's current location and update the weatherTemplate
            do {
                let result = try await DataService().getWeather(latitude: latitude, longitude: longitude)
                template.items.removeAll()
                template.items.append(CPInformationItem(title: "City", detail: city))
                template.items.append(CPInformationItem(title: "Temperature", detail: String(result.temperature)))
                template.items.append(CPInformationItem(title: "Air Quality Index", detail: String(result.aqIndex)))
                
                // Now present AQI alert
//                DispatchQueue.main.async {
//                    self.presentAQIAlert(aqi: Int(result.aqIndex))
//                }
            } catch {
                print("Error fetching weather: \(error)")
            }
        }
    }
}

extension CarPlaySceneDelegate: LocationServiceDelegate {
    
    // event fired from the location service every time the user's location changes by 1/2 mile
    // update template content based on the user's new location
    
    func locationService(latitude: Double, longitude: Double, city: String) {
        Task {
            await getWeather(template: self.weatherTemplate!, latitude: latitude, longitude: longitude, city: city)
            await getPlaces(template: self.coffeeTemplate!, latitude: latitude, longitude: longitude, placeType: PlaceType.coffee)
            await getPlaces(template: self.fuelTemplate!, latitude: latitude, longitude: longitude, placeType: PlaceType.fuel)
            await getPlaces(template: self.foodTemplate!, latitude: latitude, longitude: longitude, placeType: PlaceType.food)
        }
    }
}

extension CarPlaySceneDelegate: VehicleMessageServiceDelegate {
    
    // event fired when a new message is received from the vehicle message subscription
    // display the message as an Alert template
    
    func vehicleMessageService(message: String) {
        
        print("CarPlay received message from Cloud: \(message)")
        
        if (!self.vehicleMessageDisplayed){
            
            let okAction = CPAlertAction(title: "OK", style: CPAlertAction.Style.default, handler: {item in
                print("OK button pressed")
                self.interfaceController?.dismissTemplate(animated: true, completion: nil)
                self.vehicleMessageDisplayed = false
            })
            
            let actionTemplate = CPActionSheetTemplate(title: "New Message", message: message, actions: [okAction])

            self.interfaceController?.presentTemplate(actionTemplate,animated: true, completion: nil)
            
            self.vehicleMessageDisplayed = true
        }
    }
}
