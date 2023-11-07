//
//  SettingsView.swift
//  mobile
//
//  Created by Xiao Fei on 11/7/23.
//

import SwiftUI

struct SettingsView: View {
    
    @Binding var showSettings: Bool
    @State private var weatherAlerts = false
    @State private var airQualityNotification = false
    
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
                    
                    Toggle(isOn: $airQualityNotification) {
                        Text("Air Quality Notification")
                    }
                }
            }
            
            Spacer()
            FormButton(label: "Dismiss", action: {showSettings.toggle()})
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
