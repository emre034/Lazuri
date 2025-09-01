//
//  UserDataManager.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Data Models
@MainActor
class UserDataManager: ObservableObject {
    
    static let shared = UserDataManager()
    
    private let userDefaults: UserDefaults?
    
    // MARK: - Keys
    private let totalFlashcardsViewedKey = "totalFlashcardsViewed"
    
    // MARK: - Published Properties
    @Published var totalFlashcardsViewed: Int = 0
    
    // MARK: - Achievement Thresholds
    private let flashcardThresholds = [5, 10, 25, 50, 75, 100]
    
    // MARK: - Achievement Points (from Apple Store Connect)
    private let achievementPoints: [String: Int] = [
        "com.emrekulaber.lazuri.cards5": 10,
        "com.emrekulaber.lazuri.cards10": 15,
        "com.emrekulaber.lazuri.cards25": 25,
        "com.emrekulaber.lazuri.cards50": 40,
        "com.emrekulaber.lazuri.cards75": 60,
        "com.emrekulaber.lazuri.cards100": 80
    ]
    
    private init() {
        userDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri")
        if userDefaults == nil {
            print("Warning: Failed to initialize UserDefaults with app group")
        }
        loadData()
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        guard let userDefaults = userDefaults else { return }
        
        totalFlashcardsViewed = userDefaults.integer(forKey: totalFlashcardsViewedKey)
    }
    
    // Public method to refresh data from shared defaults
    func refreshFromSharedDefaults() {
        loadData()
        // Check achievements after refreshing data
        checkFlashcardAchievements()
    }
    
    private func saveData() {
        guard let userDefaults = userDefaults else { return }
        
        userDefaults.set(totalFlashcardsViewed, forKey: totalFlashcardsViewedKey)
        userDefaults.synchronize()
    }
    
    // MARK: - Flashcard Tracking
    func incrementFlashcardCount() {
        print("Incrementing flashcard count")
        print("Total BEFORE: \(totalFlashcardsViewed)")
        
        totalFlashcardsViewed += 1
        saveData()
        
        print("Total AFTER: \(totalFlashcardsViewed)")
        print("Calling checkFlashcardAchievements...")
        
        checkFlashcardAchievements()
        
        // Submit total achievement score to Game Center leaderboard
        let totalScore = calculateTotalScore()
        print("  - Submitting total achievement score to leaderboard: \(totalScore)")
        GameCenterManager.shared.submitScore(totalScore)
    }
    
    private func checkFlashcardAchievements() {
        print("Checking flashcard achievements")
        print("Current total: \(totalFlashcardsViewed)")
        print("Thresholds to check: \(flashcardThresholds)")
        
        for threshold in flashcardThresholds {
            if totalFlashcardsViewed >= threshold {
                let achievementId = "com.emrekulaber.lazuri.cards\(threshold)"
                let isUnlocked = isAchievementUnlocked(achievementId)
                
                print("Threshold \(threshold): REACHED")
                print("Achievement ID: \(achievementId)")
                print("Already unlocked: \(isUnlocked)")
                
                if !isUnlocked {
                    print("Unlocking achievement!")
                    unlockAchievement(achievementId)
                }
            } else {
                print("Threshold \(threshold): Not reached yet")
            }
        }
    }
    
    
    // MARK: - Achievement Management
    private func isAchievementUnlocked(_ achievementId: String) -> Bool {
        let key = "achievement_\(achievementId)_unlocked"
        return userDefaults?.bool(forKey: key) ?? false
    }
    
    private func unlockAchievement(_ achievementId: String) {
        // Save unlock status
        let key = "achievement_\(achievementId)_unlocked"
        userDefaults?.set(true, forKey: key)
        
        // Report to Game Center
        GameCenterManager.shared.reportAchievement(
            identifier: achievementId,
            percentComplete: 100.0
        )
        
        // Notify UI
        NotificationCenter.default.post(
            name: Notification.Name("AchievementUnlocked"),
            object: achievementId
        )
    }
    
    
    // MARK: - Total Score Calculation
    func calculateTotalScore() -> Int {
        var totalScore = 0
        
        // Add points for all unlocked achievements
        for (achievementId, points) in achievementPoints {
            if isAchievementUnlocked(achievementId) {
                totalScore += points
                print("Adding \(points) points for \(achievementId)")
            }
        }
        
        print("Total Score: \(totalScore)")
        return totalScore
    }
}

