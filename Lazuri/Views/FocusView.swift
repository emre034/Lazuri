//
//  FocusView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import SwiftUI
import FamilyControls
import DeviceActivity
import Charts

struct FocusView: View {
    // TODO: Add pull-to-refresh for usage stats (could be alternative to 60s refresh)
    // FIXME: Screen Time Chart is slow on first load
    @StateObject private var authManager = AuthorizationManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var deviceActivityManager = DeviceActivityManager.shared
    @StateObject private var focusTracker = FocusTracker.shared
    
    @State private var showingActivityPicker = false
    @State private var showingScheduleCreator = false
    @State private var selectedChartPeriod: ChartPeriod = .week
    @State private var scheduleToEdit: ScheduleConfiguration?
    @State private var selectedScreenTimePeriod: ScreenTimePeriod = .today
    
    // Timer for live updates
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 20) {
                    // Time Saved Section - only show when authorized
                    if authManager.isAuthorized {
                        timeSavedSection
                    }
                    
                    // Only show authorization section if not authorized
                    if !authManager.isAuthorized {
                        authorizationSection
                    }
                    
                    if authManager.isAuthorized {
                        // Screen Time Chart
                        screenTimeChartSection
                        
                        // Schedules Section (now includes App Selection)
                        schedulesSection
                        
                        // Usage Statistics
                        usageChartSection
                    }
                    }
                    .padding()
                    .padding(.top, 7) // Reduced space for status bar
                }
                
                // Status bar background that adapts to color scheme
                VStack {
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .frame(height: 50)
                        .ignoresSafeArea()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .familyActivityPicker(
                isPresented: $showingActivityPicker,
                selection: $screenTimeManager.activitySelection
            )
            .onChange(of: screenTimeManager.activitySelection) { _, newSelection in
                screenTimeManager.saveFamilyActivitySelection(newSelection)
            }
            .sheet(isPresented: $showingScheduleCreator) {
                ScheduleCreatorView()
            }
            .sheet(item: $scheduleToEdit) { schedule in
                ScheduleEditView(schedule: schedule)
            }
            .onAppear {
                // Check authorization status when view appears
                authManager.updateAuthorizationStatus()
                
                // Restore active schedules
                deviceActivityManager.restoreActiveSchedules()
                
                // Refresh focus data from shared defaults
                focusTracker.refreshFromSharedDefaults()
                
                // Automatically request authorization if not determined
                if authManager.authorizationStatus == .notDetermined {
                    Task {
                        await authManager.requestAuthorization()
                    }
                }
                
                // Auto-trigger Screen Time chart loading with single toggle
                if authManager.isAuthorized {
                    Task {
                        // Single toggle cycle to force chart initialization
                        // Forces SwiftUI to redraw the chart properly
                        await MainActor.run {
                            selectedScreenTimePeriod = .week
                        }
                        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms delay
                        
                        await MainActor.run {
                            selectedScreenTimePeriod = .today
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusDataUpdated)) { _ in
                // Refresh when notified of new data
                focusTracker.refreshFromSharedDefaults()
            }
            .onReceive(timer) { _ in
                // Refresh data every minute
                focusTracker.refreshFromSharedDefaults()
            }
        }
    }
}

// MARK: - Screen Time Period
enum ScreenTimePeriod: String, CaseIterable {
    case today = "Today"
    case week = "Week"
}

// MARK: - View Extensions
private extension FocusView {
    
    // MARK: - Time Saved Section (moved from Compete)
    private var timeSavedSection: some View {
        VStack(spacing: 20) {
            // Hourglass icon - bigger and centered
            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text("Minutes that served you, not your screen!")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("\(focusTracker.totalFocusMinutes) minutes")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.blue)
                
                if focusTracker.totalFocusMinutes >= 60 {
                    Text(formatHoursAndMinutes(focusTracker.totalFocusMinutes))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Updates periodically")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func formatHoursAndMinutes(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours) hour(s) \(minutes) minute(s)"
        } else if hours > 0 {
            return "\(hours) hour(s)"
        }
        return ""
    }
    
    // MARK: - Screen Time Chart Section
    private var screenTimeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Time")
                .font(.system(size: 20, weight: .semibold))
            
            // Time Range Picker
            Picker("Time Range", selection: $selectedScreenTimePeriod) {
                ForEach(ScreenTimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Device Activity Report
            DeviceActivityReport(DeviceActivityReport.Context("Total Activity"), filter: screenTimeFilter)
                .frame(height: 525)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var screenTimeFilter: DeviceActivityFilter {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedScreenTimePeriod {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return DeviceActivityFilter(
                segment: .hourly(
                    during: DateInterval(start: startOfDay, end: now)
                )
            )
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return DeviceActivityFilter(
                segment: .daily(
                    during: DateInterval(start: weekAgo, end: now)
                )
            )
        }
    }
    
    // MARK: - Authorization Section
    var authorizationSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Screen Time Permission Required")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("A permission request will appear automatically in a few seconds. If it doesn’t, please follow the steps below:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Text("1.")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("Go to Settings > Screen Time")
                        .font(.subheadline)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("2.")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("Scroll down to the 'Apps with Screen Time Access' section and toggle on Lazuri")
                        .font(.subheadline)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("3.")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("All done! Return to Lazuri and start using Focus mode")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                if let url = URL(string: "App-prefs:") {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("Open Settings", systemImage: "gear")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Schedules Section
    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Selection (moved here)
            VStack(alignment: .leading, spacing: 12) {
                Text("App Selection")
                    .font(.headline)
                
                HStack {
                    let appsCount = screenTimeManager.activitySelection.applicationTokens.count
                    let categoriesCount = screenTimeManager.activitySelection.categoryTokens.count
                    
                    if appsCount == 0 && categoriesCount == 0 {
                        // No selection
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.gray)
                        Text("No selection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        // Show only what's selected
                        if appsCount > 0 {
                            Image(systemName: "apps.iphone")
                                .foregroundColor(.blue)
                            Text("\(appsCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("apps selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if categoriesCount > 0 {
                            if appsCount > 0 {
                                Text("•")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "folder.fill")
                                .foregroundColor(.orange)
                            Text("\(categoriesCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(categoriesCount == 1 ? "category" : "categories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Check if any schedule is active
                let hasActiveSchedule = screenTimeManager.scheduleConfigurations.contains(where: { $0.isActive })
                
                Button("Select Apps to Block") {
                    showingActivityPicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasActiveSchedule ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(hasActiveSchedule)
                
                if hasActiveSchedule {
                    Text("Disable active schedule to change app selection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Schedules
            HStack {
                Text("Blocking Schedules")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingScheduleCreator = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            if screenTimeManager.scheduleConfigurations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("No schedules created yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap + to create a blocking schedule")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(screenTimeManager.scheduleConfigurations) { schedule in
                    ScheduleRowView(schedule: schedule)
                        .onTapGesture {
                            // Only allow editing if schedule is not active
                            if !schedule.isActive {
                                scheduleToEdit = schedule
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Chart Helpers
    private var xAxisLabel: String {
        switch selectedChartPeriod {
        case .day:
            return "Hour"
        case .week:
            return "Day"
        }
    }
    
    private var xAxisLabelText: String {
        switch selectedChartPeriod {
        case .day:
            return "Time of Day"
        case .week:
            return "Day of Week"
        }
    }
    
    private var barWidth: MarkDimension {
        switch selectedChartPeriod {
        case .day:
            return .ratio(0.8)
        case .week:
            return .ratio(0.7)
        }
    }
    
    private var xAxisUnit: Calendar.Component {
        switch selectedChartPeriod {
        case .day:
            return .hour
        case .week:
            return .day
        }
    }
    
    // MARK: - Usage Chart Section
    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Time")
                .font(.headline)
            
            // Time Range Picker
            Picker("Time Range", selection: $selectedChartPeriod) {
                ForEach(ChartPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Chart View
            let chartData = focusTracker.getChartData(for: selectedChartPeriod)
            
            if chartData.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("Nothing to show yet!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your focus time will appear here once you start using blocking schedules.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    // Summary info
                    HStack {
                        let totalMinutes = chartData.reduce(0) { $0 + $1.durationMinutes }
                        if totalMinutes > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(spacing: 4) {
                                        Text("\(totalMinutes)")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text("min")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    if totalMinutes >= 60 {
                                        Text("(\(totalMinutes / 60) hour\(totalMinutes / 60 == 1 ? "" : "s") \(totalMinutes % 60) min)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                        // Average indicator
                        if !chartData.isEmpty {
                            let nonZeroSessions = chartData.filter { $0.durationMinutes > 0 }
                            if !nonZeroSessions.isEmpty {
                                let average = nonZeroSessions.reduce(0) { $0 + $1.durationMinutes } / nonZeroSessions.count
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Average")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .trailing, spacing: 0) {
                                        HStack(spacing: 4) {
                                            Text("\(average)")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                            Text("min")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        if average >= 60 {
                                            Text("(\(average / 60) hour\(average / 60 == 1 ? "" : "s") \(average % 60) min)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Chart(chartData) { session in
                        BarMark(
                            x: .value(xAxisLabel, session.date, unit: xAxisUnit),
                            y: .value("Focus Time", session.durationMinutes),
                            width: barWidth
                        )
                        .foregroundStyle(
                            session.durationMinutes > 0 
                            ? LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                        )
                        .cornerRadius(8)
                    }
                .frame(height: 300)
                .padding(.top, 8)
                .chartXAxis {
                    switch selectedChartPeriod {
                    case .day:
                        AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel() {
                                if let date = value.as(Date.self) {
                                    Text("\(Calendar.current.component(.hour, from: date), specifier: "%02d")")
                                        .font(.caption2)
                                }
                            }
                        }
                    case .week:
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel() {
                                if let date = value.as(Date.self) {
                                    let weekday = Calendar.current.component(.weekday, from: date)
                                    // Sunday=1, Monday=2, etc. in Calendar
                                    let dayLabel = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday - 1]
                                    Text(dayLabel)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartXAxisLabel(alignment: .center) {
                    Text(xAxisLabelText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .chartYScale(domain: 0...max(chartData.map { $0.durationMinutes }.max() ?? 1, 10))
                }
                .animation(.easeInOut(duration: 0.3), value: selectedChartPeriod)
                .animation(.easeInOut(duration: 0.3), value: chartData)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func deleteSchedule(_ schedule: ScheduleConfiguration) {
        // Stop monitoring if this schedule is active
        if schedule.isActive {
            deviceActivityManager.stopMonitoring(scheduleId: schedule.id.uuidString)
        }
        
        // Delete the schedule
        screenTimeManager.deleteSchedule(schedule)
    }
    
}

// MARK: - Schedule Row View
struct ScheduleRowView: View {
    let schedule: ScheduleConfiguration
    @StateObject private var deviceActivityManager = DeviceActivityManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isToggling = false
    @State private var toggleWorkItem: DispatchWorkItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text(schedule.formattedTimeRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Show if schedule crosses midnight
                        if schedule.endHour < schedule.startHour || 
                           (schedule.endHour == schedule.startHour && schedule.endMinute <= schedule.startMinute) {
                            Image(systemName: "moon.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(schedule.formattedDays)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if !schedule.isActive {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("", isOn: Binding(
                        get: { schedule.isActive },
                        set: { newValue in
                            // Prevent changes while another toggle is in progress
                            guard !isToggling else { return }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                toggleSchedule(newValue)
                            }
                        }
                    ))
                    .labelsHidden()
                    .disabled(isToggling)
                }
            }
            
            if schedule.isActive {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Active - cannot edit while running")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(schedule.isActive ? Color.blue.opacity(0.1) : Color(.systemGray5))
        .cornerRadius(10)
        .opacity(isToggling ? 0.6 : 1.0)
    }
    
    private func toggleSchedule(_ newValue: Bool) {
        // Cancel any pending toggle operations
        toggleWorkItem?.cancel()
        
        // Set toggling state immediately for UI feedback
        isToggling = true
        // print("Debug: Toggle requested - \(newValue)")
        
        // Create a new work item with debouncing
        let workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                self.performToggle(newValue)
            }
        }
        
        toggleWorkItem = workItem
        
        // Debounce: wait 300ms before executing to prevent rapid toggles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func performToggle(_ newValue: Bool) {
        if schedule.isActive == newValue {
            isToggling = false
            return
        }
        
        if newValue {
            // Deactivate all other schedules first
            for otherSchedule in screenTimeManager.scheduleConfigurations where otherSchedule.id != schedule.id && otherSchedule.isActive {
                var deactivatedSchedule = otherSchedule
                deactivatedSchedule.isActive = false
                screenTimeManager.updateSchedule(deactivatedSchedule)
                deviceActivityManager.stopMonitoring(scheduleId: otherSchedule.id.uuidString)
            }
        }
        
        var updatedSchedule = schedule
        updatedSchedule.isActive = newValue
        
        if newValue {
            // Start monitoring
            do {
                try deviceActivityManager.startMonitoring(
                    schedule: updatedSchedule,
                    selection: screenTimeManager.activitySelection
                )
                // Only update schedule if monitoring started successfully
                screenTimeManager.updateSchedule(updatedSchedule)
                print("Successfully activated schedule: \(schedule.name)")
            } catch {
                print("Failed to start monitoring: \(error)")
                // Don't update the schedule state if monitoring failed
                DispatchQueue.main.async {
                    self.isToggling = false
                }
                return
            }
        } else {
            // Stop monitoring first, then update state
            deviceActivityManager.stopMonitoring(scheduleId: schedule.id.uuidString)
            screenTimeManager.updateSchedule(updatedSchedule)
            print("Successfully deactivated schedule: \(schedule.name)")
        }
        
        // Reset toggling state after operation completes
        DispatchQueue.main.async {
            self.isToggling = false
        }
    }
}

#Preview {
    FocusView()
}
