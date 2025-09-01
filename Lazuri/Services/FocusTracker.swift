//
//  FocusTracker.swift
//  Lazuri
//
//  Created by Emre Kulaber on 15/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Data Models
// TODO: Plan focus session categories (work, study, personal)
struct FocusSession: Codable, Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let durationMinutes: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case durationMinutes
    }
    
    static func == (lhs: FocusSession, rhs: FocusSession) -> Bool {
        lhs.date == rhs.date && lhs.durationMinutes == rhs.durationMinutes
    }
}

@MainActor
class FocusTracker: ObservableObject {
    static let shared = FocusTracker()
    
    private let userDefaults: UserDefaults?
    
    // MARK: - Keys
    private let focusSessionsKey = "focusSessions"
    private let totalFocusMinutesKey = "totalFocusMinutes"
    
    // MARK: - Published Properties
    @Published var focusSessions: [FocusSession] = []
    @Published var totalFocusMinutes: Int = 0
    
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
        
        // Load total minutes
        totalFocusMinutes = userDefaults.integer(forKey: totalFocusMinutesKey)
        
        // Load sessions
        if let sessionsData = userDefaults.data(forKey: focusSessionsKey) {
            do {
                focusSessions = try JSONDecoder().decode([FocusSession].self, from: sessionsData)
                print("Loaded \(focusSessions.count) focus sessions")
            } catch {
                print("Failed to decode focus sessions: \(error)")
                focusSessions = []
            }
        }
        
        // Merge any pending sessions from extension
        mergePendingSessions()
    }
    
    private func mergePendingSessions() {
        guard let userDefaults = userDefaults else { return }
        
        // Check if there are pending sessions
        guard userDefaults.bool(forKey: "hasPendingFocusData"),
              let pendingArray = userDefaults.array(forKey: "pendingFocusSessions") as? [[String: Any]] else {
            return
        }
        
        var newSessionsCount = 0
        
        // Process each pending session
        for sessionData in pendingArray {
            if let date = sessionData["date"] as? Date,
               let minutes = sessionData["durationMinutes"] as? Int,
               let _ = sessionData["id"] as? String {
                
                // Check if session already exists (prevent duplicates)
                let exists = focusSessions.contains { session in
                    // Compare by approximate time (within 1 second) and duration
                    abs(session.date.timeIntervalSince(date)) < 1.0 && session.durationMinutes == minutes
                }
                
                if !exists {
                    let newSession = FocusSession(date: date, durationMinutes: minutes)
                    focusSessions.append(newSession)
                    newSessionsCount += 1
                }
            }
        }
        
        if newSessionsCount > 0 {
            print("Merged \(newSessionsCount) new sessions from extension")
            
            // Save updated sessions
            saveData()
            
            // Notify UI to update
            NotificationCenter.default.post(name: .focusDataUpdated, object: nil)
        }
        
        // Clear pending data
        userDefaults.removeObject(forKey: "pendingFocusSessions")
        userDefaults.set(false, forKey: "hasPendingFocusData")
        userDefaults.synchronize()
    }
    
    private func saveData() {
        guard let userDefaults = userDefaults else { return }
        
        // Save total minutes
        userDefaults.set(totalFocusMinutes, forKey: totalFocusMinutesKey)
        
        // Save sessions
        do {
            let sessionsData = try JSONEncoder().encode(focusSessions)
            userDefaults.set(sessionsData, forKey: focusSessionsKey)
        } catch {
            print("Failed to encode focus sessions: \(error)")
        }
        
        userDefaults.synchronize()
    }
    
    // MARK: - Public Methods
    func recordFocusSession(durationMinutes: Int) {
        print("Recording focus session: \(durationMinutes) minutes")
        
        // Create new session
        let session = FocusSession(date: Date(), durationMinutes: durationMinutes)
        focusSessions.append(session)
        
        // Update total
        totalFocusMinutes += durationMinutes
        
        // Save
        saveData()
        
        print("Total focus time: \(totalFocusMinutes) minutes")
    }
    
    func refreshFromSharedDefaults() {
        loadData()
    }
    
    // MARK: - Chart Data
    func getChartData(for period: ChartPeriod) -> [FocusSession] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        }
        
        // Filter sessions within the date range
        let filteredSessions = focusSessions.filter { $0.date >= startDate }
        
        // Decide aggregation based on period
        switch period {
        case .day:
            return getHourlyAggregatedData(from: filteredSessions, startDate: startDate)
        case .week:
            return getDailyAggregatedData(from: filteredSessions, days: 7, startDate: startDate)
        }
    }
    
    // MARK: - Aggregation Helpers
    private func getHourlyAggregatedData(from sessions: [FocusSession], startDate: Date) -> [FocusSession] {
        let calendar = Calendar.current
        
        // Group by hour
        let groupedByHour = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: session.date)
            return calendar.date(from: components) ?? session.date
        }
        
        // Create data for all 24 hours
        var hourlyData: [FocusSession] = []
        for hour in 0..<24 {
            let hourDate = calendar.date(byAdding: .hour, value: hour, to: startDate) ?? startDate
            let sessionsInHour = groupedByHour[hourDate] ?? []
            let totalMinutes = sessionsInHour.reduce(0) { $0 + $1.durationMinutes }
            hourlyData.append(FocusSession(date: hourDate, durationMinutes: totalMinutes))
        }
        
        return hourlyData
    }
    
    private func getDailyAggregatedData(from sessions: [FocusSession], days: Int, startDate: Date) -> [FocusSession] {
        let calendar = Calendar.current
        
        // Group by day
        let groupedByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        
        // Create data for all days in range
        var dailyData: [FocusSession] = []
        for dayOffset in 0..<days {
            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
            let sessionsInDay = groupedByDay[dayDate] ?? []
            let totalMinutes = sessionsInDay.reduce(0) { $0 + $1.durationMinutes }
            dailyData.append(FocusSession(date: dayDate, durationMinutes: totalMinutes))
        }
        
        return dailyData
    }
}

// MARK: - Chart Period Enum
enum ChartPeriod: String, CaseIterable {
    case day = "Today"
    case week = "This Week"
}
