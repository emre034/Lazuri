//
//  AuthorizationManager.swift
//  Lazuri
//
//  Created by Emre Kulaber on 08/07/2025.
//

import SwiftUI
import FamilyControls

@MainActor
class AuthorizationManager: ObservableObject {
    static let shared = AuthorizationManager()
    
    @Published var authorizationStatus: FamilyControls.AuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    
    private init() {
        // Simply check the actual authorization status
        // FamilyControls authorization is system managed and persistent
        updateAuthorizationStatus()
        // print("AuthManager init complete")
    }
    
    func updateAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        authorizationStatus = status
        isAuthorized = status == .approved
        print("Authorization status: \(status.description)")
    }
    
    func requestAuthorization() async {
        do {
            // Show iOS permission dialog
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            updateAuthorizationStatus()
        } catch {
            // print("Authorization failed: \(error)")
            // User cancelled authorization
            updateAuthorizationStatus()
        }
    }
}

// Extension for status description
extension FamilyControls.AuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }
}
