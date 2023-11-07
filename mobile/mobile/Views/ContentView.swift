import SwiftUI

struct ContentView: View {
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        MapView()
            .environmentObject(userSettings)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
