//
//  DeviceActivityManager.swift
//  Lazuri
//
//  Created by Emre Kulaber on 08/07/2025.
//

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

enum DeviceActivityError: Error {
    case intervalTooShort
}

class DeviceActivityManager: ObservableObject {

    // FIXME: Sometimes monitoring doesn't stop properly when app crashes
    static let shared = DeviceActivityManager()
    
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    @Published var isMonitoring: [String: Bool] = [:]
    
    // Track active sessions
    private var activeSessions: [String: Date] = [:] // scheduleId: startTime
    
    private init() {}
    
    // MARK: - Schedule Monitoring
    func startMonitoring(schedule: ScheduleConfiguration, selection: FamilyActivitySelection) throws {
        let activityName = DeviceActivityName(schedule.id.uuidString)
        
        // This allows iOS to handle the schedule on the correct days
        let startComponents = DateComponents(hour: schedule.startHour, minute: schedule.startMinute)
        let endComponents = DateComponents(hour: schedule.endHour, minute: schedule.endMinute)
        
        // Validate minimum interval with proper midnight handling
        let startMinutes = schedule.startHour * 60 + schedule.startMinute
        let endMinutes = schedule.endHour * 60 + schedule.endMinute
        
        // Calculate actual duration considering midnight crossing
        let duration: Int
        if endMinutes <= startMinutes {
            // Schedule crosses midnight
            duration = (24 * 60 - startMinutes) + endMinutes
            print("Schedule crosses midnight. Duration: \(duration) minutes")
        } else {
            // Normal schedule within same day
            duration = endMinutes - startMinutes
        }
        
        // Check minimum duration requirement
        if duration < 15 {
            print("Schedule interval too short. Duration: \(duration) minutes. Minimum is 15 minutes")
            throw DeviceActivityError.intervalTooShort
        }
        
        // Create the schedule - iOS will handle the selected days automatically
        let deviceSchedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )
        
        // Start monitoring
        try center.startMonitoring(activityName, during: deviceSchedule)
        
        // Update state
        isMonitoring[schedule.id.uuidString] = true
        ScreenTimeManager.shared.setMonitoringState(activityName: schedule.id.uuidString, isActive: true)
        
        // Track session start time
        activeSessions[schedule.id.uuidString] = Date()
        
        print("Started monitoring for schedule: \(schedule.name)")
    }
    
    func stopMonitoring(scheduleId: String) {
        let activityName = DeviceActivityName(scheduleId)
        
        center.stopMonitoring([activityName])
        
        // Update state
        isMonitoring[scheduleId] = false
        ScreenTimeManager.shared.setMonitoringState(activityName: scheduleId, isActive: false)
        
        // Calculate and record blocking time if there was an active session
        if let startTime = activeSessions[scheduleId] {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            let minutes = Int(duration / 60)
            
            // Skip if duration is 0
            if minutes > 0 {
                // Save to pending sessions to avoid race condition
                if let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri") {
                    let sessionId = "\(scheduleId)_\(startTime.timeIntervalSince1970)"
                    let sessionData: [String: Any] = [
                        "id": sessionId,
                        "date": endTime,
                        "durationMinutes": minutes,
                        "source": "app"
                    ]
                    
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
                    sharedDefaults.synchronize()
                    
                    // Notify UI to update
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .focusDataUpdated, object: nil)
                    }
                    
                    print("Recorded blocking time: \(minutes) minutes")
                }
            }
            activeSessions.removeValue(forKey: scheduleId)
        }
        
        print("Stopped monitoring for schedule ID: \(scheduleId)")
    }
    
    func stopAllMonitoring() {
        center.stopMonitoring()
        isMonitoring.removeAll()
        
        // Clear all monitoring states
        ScreenTimeManager.shared.scheduleConfigurations.forEach { schedule in
            ScreenTimeManager.shared.setMonitoringState(activityName: schedule.id.uuidString, isActive: false)
        }
        
        print("Stopped all monitoring")
    }
    
    // MARK: - Check Monitoring Status
    func checkMonitoringStatus(for scheduleId: String) -> Bool {
        return ScreenTimeManager.shared.getMonitoringState(activityName: scheduleId)
    }
    
    // MARK: - Restore Active Schedules
    func restoreActiveSchedules() {
        let screenTimeManager = ScreenTimeManager.shared
        
        for schedule in screenTimeManager.scheduleConfigurations where schedule.isActive {
            do {
                try startMonitoring(schedule: schedule, selection: screenTimeManager.activitySelection)
            } catch {
                print("Failed to restore schedule \(schedule.name): \(error)")
                // Update the schedule to inactive if it failed to start
                var updatedSchedule = schedule
                updatedSchedule.isActive = false
                screenTimeManager.updateSchedule(updatedSchedule)
            }
        }
    }
    
}
