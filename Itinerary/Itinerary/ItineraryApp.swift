//
//  ItineraryApp.swift
//  Itinerary
//
//  Created by Kyle Lee on 10/9/24.
//

import SwiftUI
import Firebase

@main
struct ITineraryApp: App {
    init() {
        configureFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
    
    private func configureFirebase() {
        do {
            try FirebaseApp.configure() // Attempt to configure Firebase
        } catch {
            // Log or handle configuration error
            print("Firebase configuration failed: \(error.localizedDescription)")
        }
    }
    
}
