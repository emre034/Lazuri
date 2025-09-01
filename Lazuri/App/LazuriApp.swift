//
//  LazuriApp.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import SwiftUI
import UserNotifications

@main
struct LazuriApp: App {
    init() {
        // Initialize Game Center authentication on app launch  
        GameCenterManager.shared.authenticateUser()
        //print("App launching...")
        
        // Initialize UserDataManager to start tracking
        _ = UserDataManager.shared
        
        // Initialize Screen Time managers
        _ = AuthorizationManager.shared
        _ = ScreenTimeManager.shared
        
        // Request notification permissions
        requestNotificationPermissions() 
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Restore active schedules
                    // Known issue: May need manual restoration after crash
                    DeviceActivityManager.shared.restoreActiveSchedules()
                    
                    // Check for pending focus data
                    Task { @MainActor in
                        // Requires MainActor for UI updates
                        FocusTracker.shared.refreshFromSharedDefaults()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Check for pending data when app comes to foreground
                    Task { @MainActor in
                        FocusTracker.shared.refreshFromSharedDefaults()
                    }
                }
        }
    }
    
    private func requestNotificationPermissions() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted {
                print("Notification permissions granted")
            } else {
                // print("Notification permissions error")
                // Non-critical error, continue without notifications
            }
        }
    }
}
