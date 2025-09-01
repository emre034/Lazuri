//
//  ScheduleCreatorView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 08/07/2025.
//

import SwiftUI

struct ScheduleCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    @State private var scheduleName = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Monday-Friday default
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    
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
                
                // Summary
                Section("Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Schedule will block selected apps", systemImage: "lock.fill")
                            .font(.subheadline)
                        
                        Label("Repeats \(formattedDays)", systemImage: "repeat")
                            .font(.subheadline)
                        
                        HStack {
                            Label("From \(formattedTime(startTime)) to \(formattedTime(endTime))", systemImage: "clock")
                                .font(.subheadline)
                            
                            if endTime <= startTime {
                                Text("(next day)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Show duration
                        Label("\(formattedDuration) duration", systemImage: "timer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Create Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createSchedule()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canCreateSchedule)
                }
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
    
    private var canCreateSchedule: Bool {
        !scheduleName.isEmpty && !selectedDays.isEmpty && isValidTimeRange
    }
    
    private var formattedDuration: String {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else {
            return "0 min"
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
        
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var formattedDays: String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let selectedDayNames: [String] = selectedDays.sorted().compactMap { (day: Int) -> String? in
            guard day >= 1 && day <= 7 else { return nil }
            return dayNames[day - 1]
        }
        
        if selectedDayNames.count == 7 {
            return "every day"
        } else if selectedDayNames == ["Mon", "Tue", "Wed", "Thu", "Fri"] {
            return "weekdays"
        } else if selectedDayNames == ["Sat", "Sun"] {
            return "weekends"
        } else {
            return selectedDayNames.joined(separator: ", ")
        }
    }
    
    // MARK: - Helper Methods
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func createSchedule() {
        // Final validation
        guard canCreateSchedule else {
            validationErrorMessage = "Please fill in all required fields"
            showingValidationError = true
            return
        }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let schedule = ScheduleConfiguration(
            name: scheduleName,
            startTime: startComponents,
            endTime: endComponents,
            days: Array(selectedDays)
        )
        
        screenTimeManager.saveSchedule(schedule)
        dismiss()
    }
}

// MARK: - Day Button Component
struct DayButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScheduleCreatorView()
}