//
//  GameCenterView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 15/07/2025.
//

import SwiftUI
import GameKit

// UIKit wrapper for Game Center
// Standard Game Center implementation
struct GameCenterView: UIViewControllerRepresentable {
    let viewState: GKGameCenterViewControllerState
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let gameCenter = GKGameCenterViewController(state: viewState)
        gameCenter.gameCenterDelegate = context.coordinator
        // Limited customization available for Game Center views
        return gameCenter
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {
        // No updates needed
        // Game Center manages its own state
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView
        
        init(_ parent: GameCenterView) {
            self.parent = parent
        }
        
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            parent.isPresented = false // Dismiss sheet
        }
    }
}