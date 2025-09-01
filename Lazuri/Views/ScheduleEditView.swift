//
//  ScheduleEditView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 08/07/2025.
//

import SwiftUI

struct ScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var deviceActivityManager = DeviceActivityManager.shared
    
    let schedule: ScheduleConfiguration
    
    @State private var scheduleName: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedDays: Set<Int>
    @State private var showingDeleteAlert = false
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    
    init(schedule: ScheduleConfiguration) {
        self.schedule = schedule
        _scheduleName = State(initialValue: schedule.name)
        
        // Convert time components to Date
        let calendar = Calendar.current
        let now = Date()
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = schedule.startHour
        startComponents.minute = schedule.startMinute
        let startDate = calendar.date(from: startComponents) ?? now
        _startTime = State(initialValue: startDate)
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = schedule.endHour
        endComponents.minute = schedule.endMinute
        let endDate = calendar.date(from: endComponents) ?? now
        _endTime = State(initialValue: endDate)
        
        _selectedDays = State(initialValue: Set(schedule.selectedDays))
    }
    
    let weekdays = [
        (1, "Sun"),
        (2, "Mon"),
        (3, "Tue"),
        (4, "Wed"),
        (5, "Thu"),
        (6, "Fri"),
        (7, "Sat")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Schedule Name
                Section("Schedule Name") {
                    TextField("e.g., Work Hours, Study Time", text: $scheduleName)
                }
                
                // Time Selection
                Section("Time Range") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    // Show time validation
                    if !isValidTimeRange {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Schedule must be at least 15 minutes long")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else if endTime <= startTime {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.blue)
                            Text("Schedule crosses midnight (continues next day)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Days Selection
                Section("Active Days") {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach(weekdays, id: \.0) { day, name in
                                DayButton(
                                    day: name,
                                    isSelected: selectedDays.contains(day),
                                    action: {
                                        toggleDay(day)
                                    }
                                )
                            }
                        }
                        
                        // Quick selection buttons
                        HStack(spacing: 12) {
                            Button("Weekdays") {
                                selectedDays = [2, 3, 4, 5, 6]
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            
                            Button("Weekends") {
                                selectedDays = [1, 7]
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            
                            Button("Every Day") {
                                selectedDays = Set(1...7)
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Status
                Section("Status") {
                    HStack {
                        Text("Schedule is")
                        Text(schedule.isActive ? "Active" : "Inactive")
                            .fontWeight(.semibold)
                            .foregroundColor(schedule.isActive ? .green : .secondary)
                        Spacer()
                        if schedule.isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Delete Button
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Schedule", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSaveSchedule)
                }
            }
            .alert("Delete Schedule", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSchedule()
                }
            } message: {
                Text("Are you sure you want to delete this schedule? This action cannot be undone.")
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK") { }
            } message: {
                Text(validationErrorMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isValidTimeRange: Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else {
            return false
        }
        
        let startTotal = startHour * 60 + startMinute
        let endTotal = endHour * 60 + endMinute
        
        // Calculate actual duration considering midnight crossing
        let duration: Int
        if endTotal <= startTotal {
            // Schedule crosses midnight
            duration = (24 * 60 - startTotal) + endTotal
        } else {
            // Normal schedule within same day
            duration = endTotal - startTotal
        }
        
        // Ensure at least 15 minutes difference
        return duration >= 15
    }
    
    private var canSaveSchedule: Bool {
        !scheduleName.isEmpty && !selectedDays.isEmpty && isValidTimeRange
    }
    
    // MARK: - Helper Methods
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func saveSchedule() {
        guard canSaveSchedule else {
            validationErrorMessage = "Please fill in all required fields"
            showingValidationError = true
            return
        }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        var updatedSchedule = schedule
        updatedSchedule.name = scheduleName
        updatedSchedule.startHour = startComponents.hour ?? 0
        updatedSchedule.startMinute = startComponents.minute ?? 0
        updatedSchedule.endHour = endComponents.hour ?? 0
        updatedSchedule.endMinute = endComponents.minute ?? 0
        updatedSchedule.selectedDays = Array(selectedDays)
        
        // If schedule is active and time changed, restart monitoring
        if schedule.isActive {
            deviceActivityManager.stopMonitoring(scheduleId: schedule.id.uuidString)
            
            // Try to restart with new time
            do {
                try deviceActivityManager.startMonitoring(
                    schedule: updatedSchedule,
                    selection: screenTimeManager.activitySelection
                )
            } catch {
                print("Failed to restart monitoring with new time: \(error)")
                // Keep the schedule active state but let user know
                validationErrorMessage = "Schedule updated but couldn't restart monitoring. Please toggle it off and on again."
                showingValidationError = true
            }
        }
        
        screenTimeManager.updateSchedule(updatedSchedule)
        dismiss()
    }
    
    private func deleteSchedule() {
        // Stop monitoring if active
        if schedule.isActive {
            deviceActivityManager.stopMonitoring(scheduleId: schedule.id.uuidString)
        }
        
        // Delete the schedule
        screenTimeManager.deleteSchedule(schedule)
        dismiss()
    }
}

#Preview {
    ScheduleEditView(schedule: ScheduleConfiguration(
        name: "Work Hours",
        startTime: DateComponents(hour: 9, minute: 0),
        endTime: DateComponents(hour: 17, minute: 0),
        days: [2, 3, 4, 5, 6]
    ))
}
