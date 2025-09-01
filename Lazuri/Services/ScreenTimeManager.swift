//
//  ScreenTimeManager.swift
//  Lazuri
//
//  Created by Emre Kulaber on 08/07/2025.
//

import Foundation
import FamilyControls
import DeviceActivity

// MARK: - Models
struct ScheduleConfiguration: Codable, Identifiable {
    let id: UUID
    var name: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var selectedDays: [Int] // 1=Sunday, 2=Monday, etc...
    var isActive: Bool
    let createdAt: Date
    
    init(name: String, startTime: DateComponents, endTime: DateComponents, days: [Int]) {
        self.id = UUID()
        self.name = name
        self.startHour = startTime.hour ?? 0
        self.startMinute = startTime.minute ?? 0
        self.endHour = endTime.hour ?? 23
        self.endMinute = endTime.minute ?? 59
        self.selectedDays = days
        self.isActive = false
        self.createdAt = Date()
    }
    
    var formattedTimeRange: String {
        let startString = String(format: "%02d:%02d", startHour, startMinute)
        let endString = String(format: "%02d:%02d", endHour, endMinute)
        return "\(startString) - \(endString)"
    }
    
    var formattedDays: String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let selectedDayNames: [String] = selectedDays.sorted().compactMap { (day: Int) -> String? in
            guard day >= 1 && day <= 7 else { return nil }
            return dayNames[day - 1]
        }
        
        if selectedDayNames.count == 7 {
            return "Every day"
        } else if selectedDayNames == ["Mon", "Tue", "Wed", "Thu", "Fri"] {
            return "Weekdays"
        } else if selectedDayNames == ["Sat", "Sun"] {
            return "Weekends"
        } else {
            return selectedDayNames.joined(separator: ", ")
        }
    }
}

struct UsageData: Identifiable, Codable {
    let id: UUID
    let date: Date
    let appName: String
    let minutes: Int
    
    init(date: Date, appName: String, minutes: Int) {
        self.id = UUID()
        self.date = date
        self.appName = appName
        self.minutes = minutes
    }
}

// MARK: - Screen Time Manager
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    // Use the existing app group
    private let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Keys
    enum Keys: String, CaseIterable {
        case familyActivitySelection = "ST_FamilyActivitySelection"
        case scheduleConfigurations = "ST_ScheduleConfigurations"
        case usageData = "ST_UsageData"
        case monitoringState = "ST_MonitoringState"
        case lastSyncDate = "ST_LastSyncDate"
    }
    
    @Published var activitySelection = FamilyActivitySelection()
    @Published var scheduleConfigurations: [ScheduleConfiguration] = []
    @Published var usageData: [UsageData] = []
    
    private init() {
        loadData()
    }
    
    // MARK: - FamilyActivitySelection
    func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        guard let defaults = sharedDefaults else { return }
        
        do {
            let encoded = try encoder.encode(selection)
            defaults.set(encoded, forKey: Keys.familyActivitySelection.rawValue)
            defaults.synchronize() // Force sync for extension access
            self.activitySelection = selection
            print("Saved FamilyActivitySelection with \(selection.applicationTokens.count) apps")
        } catch {
            print("Error saving FamilyActivitySelection: \(error)")
        }
    }
    
    func loadFamilyActivitySelection() -> FamilyActivitySelection? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.familyActivitySelection.rawValue) else {
            return nil
        }
        
        do {
            return try decoder.decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Error loading FamilyActivitySelection: \(error)")
            return nil
        }
    }
    
    // MARK: - Schedule Management
    func saveSchedule(_ config: ScheduleConfiguration) {
        scheduleConfigurations.append(config)
        saveAllSchedules()
    }
    
    func updateSchedule(_ config: ScheduleConfiguration) {
        if let index = scheduleConfigurations.firstIndex(where: { $0.id == config.id }) {
            scheduleConfigurations[index] = config
            saveAllSchedules()
        }
    }
    
    func deleteSchedule(_ config: ScheduleConfiguration) {
        scheduleConfigurations.removeAll { $0.id == config.id }
        saveAllSchedules()
    }
    
    func toggleSchedule(_ config: ScheduleConfiguration) {
        if let index = scheduleConfigurations.firstIndex(where: { $0.id == config.id }) {
            scheduleConfigurations[index].isActive.toggle()
            saveAllSchedules()
        }
    }
    
    private func saveAllSchedules() {
        guard let defaults = sharedDefaults else { return }
        
        do {
            let encoded = try encoder.encode(scheduleConfigurations)
            defaults.set(encoded, forKey: Keys.scheduleConfigurations.rawValue)
            defaults.synchronize()
        } catch {
            print("Error saving schedules: \(error)")
        }
    }
    
    private func loadSchedules() {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.scheduleConfigurations.rawValue) else {
            return
        }
        
        do {
            scheduleConfigurations = try decoder.decode([ScheduleConfiguration].self, from: data)
        } catch {
            print("Error loading schedules: \(error)")
        }
    }
    
    // MARK: - Usage Data
    func saveUsageData(_ data: [UsageData]) {
        guard let defaults = sharedDefaults else { return }
        
        do {
            let encoded = try encoder.encode(data)
            defaults.set(encoded, forKey: Keys.usageData.rawValue)
            defaults.synchronize()
            self.usageData = data
        } catch {
            print("Error saving usage data: \(error)")
        }
    }
    
    func loadUsageData() -> [UsageData] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.usageData.rawValue) else {
            return []
        }
        
        do {
            return try decoder.decode([UsageData].self, from: data)
        } catch {
            print("Error loading usage data: \(error)")
            return []
        }
    }
    
    // MARK: - State Management
    func setMonitoringState(activityName: String, isActive: Bool) {
        guard let defaults = sharedDefaults else { return }
        
        var states = defaults.dictionary(forKey: Keys.monitoringState.rawValue) as? [String: Bool] ?? [:]
        states[activityName] = isActive
        defaults.set(states, forKey: Keys.monitoringState.rawValue)
        defaults.synchronize()
    }
    
    func getMonitoringState(activityName: String) -> Bool {
        guard let defaults = sharedDefaults else { return false }
        
        let states = defaults.dictionary(forKey: Keys.monitoringState.rawValue) as? [String: Bool] ?? [:]
        return states[activityName] ?? false
    }
    
    // MARK: - Load All Data
    private func loadData() {
        loadSchedules()
        if let selection = loadFamilyActivitySelection() {
            self.activitySelection = selection
        }
        self.usageData = loadUsageData()
    }
    
    // MARK: - Utility Methods
    func clearAllData() {
        guard let defaults = sharedDefaults else { return }
        
        Keys.allCases.forEach { key in
            defaults.removeObject(forKey: key.rawValue)
        }
        defaults.synchronize()
        
        scheduleConfigurations = []
        activitySelection = FamilyActivitySelection()
        usageData = []
    }
}
