//
//  ContentView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MapView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
