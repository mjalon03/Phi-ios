//
//  Citizen_AlertsApp.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI

@main
struct Citizen_AlertsApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
