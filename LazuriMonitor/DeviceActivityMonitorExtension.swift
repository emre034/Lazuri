//
//  DeviceActivityMonitorExtension.swift
//  LazuriMonitor
//
//  Created by Emre Kulaber on 08/07/2025.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import UserNotifications

// Monitor extension for device activity

// MARK: - FocusSession Model
struct FocusSession: Codable {
    let date: Date
    let durationMinutes: Int
}

// MARK: - Extension to decode FamilyActivitySelection from UserDefaults
extension FamilyActivitySelection {
    static func loadFromUserDefaults() -> FamilyActivitySelection? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri"),
              let data = sharedDefaults.data(forKey: "ST_FamilyActivitySelection") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to decode FamilyActivitySelection: \(error)")
            return nil
        }
    }
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Apply restrictions when interval starts
        autoreleasepool {
            // Record start time for this activity
            if let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri") {
                let startTimeKey = "activityStartTime_\(activity.rawValue)"
                sharedDefaults.set(Date(), forKey: startTimeKey)
                sharedDefaults.synchronize()
            }
            
            applyRestrictions()
            sendNotification("Focus time started", body: "No turning back, focus begins now!")
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Remove restrictions when interval ends
        autoreleasepool {
            removeRestrictions()
            
            // Record blocking time when schedule ends naturally
            recordBlockingTimeForActivity(activity)
            
            sendNotification("Focus time ended", body: "Well done! Your discipline has won the day.")
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        sendNotification("Usage limit reached", body: "You've reached your usage limit for today")
    }
    
    
    // MARK: - Private Methods
    
    private func applyRestrictions() {
        guard let selection = FamilyActivitySelection.loadFromUserDefaults() else {
            print("No FamilyActivitySelection found in UserDefaults")
            recordRestrictionError("No apps or categories selected for blocking")
            return
        }
        
        // Apply shield to selected apps
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            print("Successfully shielded \(selection.applicationTokens.count) apps")
        }
        
        // Apply shield to selected categories
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            print("Successfully shielded \(selection.categoryTokens.count) categories")
        }
        
        // Apply shield to web domains
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
            print("Successfully shielded \(selection.webDomainTokens.count) web domains")
        }
        
        // Record success status
        clearRestrictionError()
        let appCount = selection.applicationTokens.count
        let categoryCount = selection.categoryTokens.count
        print("Successfully applied all restrictions: \(appCount) apps, \(categoryCount) categories")
    }
    
    private func removeRestrictions() {
        // Remove all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // Record success
        clearRestrictionError()
        print("Successfully removed all restrictions")
    }
    
    private func recordBlockingTimeForActivity(_ activity: DeviceActivityName) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri") else {
            print("Failed to access shared UserDefaults")
            return
        }
        
        // Get the activity start time from UserDefaults
        let startTimeKey = "activityStartTime_\(activity.rawValue)"
        guard let startTime = sharedDefaults.object(forKey: startTimeKey) as? Date else {
            print("No start time found for activity: \(activity.rawValue)")
            return
        }
        
        // Calculate duration in minutes
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        
        // Skip if duration is 0
        if minutes == 0 {
            print("Duration is 0 minutes, skipping record")
            sharedDefaults.removeObject(forKey: startTimeKey)
            return
        }
        
        // Create unique session ID
        let sessionId = "\(activity.rawValue)_\(startTime.timeIntervalSince1970)"
        
        // Create session data
        let sessionData: [String: Any] = [
            "id": sessionId,
            "date": endTime,
            "durationMinutes": minutes,
            "source": "extension"
        ]
        
        // Save to pending sessions (not main sessions to avoid race condition)
        var pendingSessions = sharedDefaults.array(forKey: "pendingFocusSessions") as? [[String: Any]] ?? []
        pendingSessions.append(sessionData)
        sharedDefaults.set(pendingSessions, forKey: "pendingFocusSessions")
        
        // Update total minutes
        let currentTotal = sharedDefaults.integer(forKey: "totalFocusMinutes")
        let newTotal = currentTotal + minutes
        sharedDefaults.set(newTotal, forKey: "totalFocusMinutes")
        
        // Set flag for new data available
        sharedDefaults.set(true, forKey: "hasPendingFocusData")
        sharedDefaults.set(Date(), forKey: "lastFocusUpdateTime")
        
        // Clean up the start time
        sharedDefaults.removeObject(forKey: startTimeKey)
        sharedDefaults.synchronize()
        
        print("Recorded \(minutes) minutes of blocking time. New total: \(newTotal) minutes")
    }
    
    private func sendNotification(_ title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    private func recordRestrictionError(_ errorMessage: String) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri") else {
            print("Failed to access shared UserDefaults to record error")
            return
        }
        
        // Store error message and timestamp
        sharedDefaults.set(errorMessage, forKey: "restrictionErrorMessage")
        sharedDefaults.set(Date(), forKey: "restrictionErrorTimestamp")
        sharedDefaults.set(true, forKey: "hasRestrictionError")
        sharedDefaults.synchronize()
        
        print("Recorded restriction error: \(errorMessage)")
    }
    
    private func clearRestrictionError() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri") else {
            print("Failed to access shared UserDefaults to clear error")
            return
        }
        
        // Clear error state
        sharedDefaults.removeObject(forKey: "restrictionErrorMessage")
        sharedDefaults.removeObject(forKey: "restrictionErrorTimestamp")
        sharedDefaults.set(false, forKey: "hasRestrictionError")
        sharedDefaults.synchronize()
        
        print("Cleared restriction error state")
    }
}
