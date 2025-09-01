//
//  GameCenterManager.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import Foundation
import GameKit

@MainActor
class GameCenterManager: NSObject, ObservableObject {
    // FIXME: Authentication rarely fails silently on first launch
    static let shared = GameCenterManager()
    
    @Published var isAuthenticated = false
    @Published var authenticationError: Error?
    
    private let leaderboardID = "com.emrekulaber.lazuri.totalpoints"
    
    private override init() {
        super.init()
    }
    
    func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let error = error {
                self.authenticationError = error
                self.isAuthenticated = false
                return
            }
            
            if let viewController = viewController {
                // Present the authentication view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(viewController, animated: true)
                }
                return
            }
            
            // Authentication successful
            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            
            if self.isAuthenticated {
                // Load any pending data
                self.loadCurrentPlayerScore()
            }
        }
    }
    
    func submitScore(_ score: Int) {
        print("Submitting score: \(score)")
        
        guard isAuthenticated else {
            print("User not authenticated, skipping score submission")
            return
        }
        
        print("User authenticated, submitting to leaderboard ID: \(leaderboardID)")
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                print("Score submitted successfully!")
            } catch {
                print("Failed to submit score: \(error)")
            }
        }
    }
    
    func reportAchievement(identifier: String, percentComplete: Double) {
        guard isAuthenticated else {
            // User not authenticated
            return
        }
        
        Task {
            do {
                let achievement = GKAchievement(identifier: identifier)
                achievement.percentComplete = percentComplete
                achievement.showsCompletionBanner = true
                
                try await GKAchievement.report([achievement])
                // Achievement reported successfully
            } catch {
                // Failed to report achievement
            }
        }
    }
    
    func loadLeaderboard() async throws -> [GKLeaderboard.Entry] {
        guard isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }
        
        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
        guard let leaderboard = leaderboards.first else {
            throw GameCenterError.leaderboardNotFound
        }
        
        let entries = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 10))
        return entries.1
    }
    
    func loadAchievements() async throws -> [GKAchievement] {
        guard isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }
        
        return try await GKAchievement.loadAchievements()
    }
    
    private func loadCurrentPlayerScore() {
        Task {
            do {
                let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
                if let leaderboard = leaderboards.first {
                    let entry = try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime)
                    if let _ = entry.1.first {
                        // Current player score loaded successfully
                    }
                }
            } catch {
                // Failed to load current player score
            }
        }
    }
}

enum GameCenterError: LocalizedError {
    case notAuthenticated
    case leaderboardNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated with Game Center"
        case .leaderboardNotFound:
            return "Leaderboard not found"
        }
    }
}
