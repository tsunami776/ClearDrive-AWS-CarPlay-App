import Amplify

// GraphQL queries to retrieve Weather and Places from the AppSync API
extension GraphQLRequest {
    
    static func getWeather(latitude: Double, longitude: Double) -> GraphQLRequest<Weather> {
        let operationName = "getWeather"
        let document = """
        query \(operationName) {
          \(operationName)(latitude: \(latitude), longitude: \(longitude)) {
            aqIndex
            temperature
            latitude
            longitude
          }
        }
        """
        
        return GraphQLRequest<Weather>(
            document: document,
            responseType: Weather.self,
            decodePath: operationName)
    }
    
    static func getPlaces(placeType: PlaceType, latitude: Double, longitude: Double, maxResults: Int) -> GraphQLRequest<[Place]> {
        let operationName = "getPlaces"
        let document = """
        query \(operationName) {
          \(operationName)(placeType: \(placeType), latitude: \(latitude), longitude: \(longitude), maxResults: \(maxResults)) {
            placeType
            name
            address
            latitude
            longitude
          }
        }
        """
        
        return GraphQLRequest<[Place]>(
            document: document,
            responseType: [Place].self,
            decodePath: operationName)
    }
    
    static func getLocation(latitude: Double, longitude: Double) -> GraphQLRequest<Location> {
        let operationName = "getLocation"
        let document = """
        query \(operationName) {
          \(operationName)(latitude: \(latitude), longitude: \(longitude)) {
            name
            latitude
            longitude
          }
        }
        """
        
        return GraphQLRequest<Location>(
            document: document,
            responseType: Location.self,
            decodePath: operationName)
    }
    
    static func createVehicleMessage(message: String, owner: String, timestamp: String) -> GraphQLRequest<VehicleMessage> {
        let operationName = "createVehicleMessage"
        
        let document = """
            mutation \(operationName)($input: CreateVehicleMessageInput!) {
              createVehicleMessage(input: $input) {
                id
                owner
                timestamp
                message
                createdAt
                updatedAt
              }
            }
            """
            
        let variables: [String: Any] = [
            "input": [
                "message": message,
                "owner": owner,
                "timestamp": timestamp
            ]
        ]
        
        return GraphQLRequest<VehicleMessage>(
            document: document,
            variables: variables,
            responseType: VehicleMessage.self,
            decodePath: operationName)
    }
}

