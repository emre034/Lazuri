//
//  TotalActivityView.swift
//  LazuriReport
//
//  Created by Emre Kulaber on 08/07/2025.
//

import SwiftUI
import Charts

struct TotalActivityView: View {
    let activityReport: ActivityReportData
    
    var body: some View {
        VStack(spacing: 0) {
            if activityReport.apps.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("No app usage data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Start using apps to see your screen time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Category chart
                        VStack(alignment: .leading, spacing: 12) {
                            GeometryReader { geometry in
                                let chartWidth = geometry.size.width * 0.95  // Scale to 95% for better use of space
                                
                                HStack(spacing: 1) {
                                    ForEach(Array(activityReport.categorizedApps.keys.sorted { cat1, cat2 in
                                        let total1 = activityReport.categorizedApps[cat1]?.reduce(0) { $0 + $1.totalDuration } ?? 0
                                        let total2 = activityReport.categorizedApps[cat2]?.reduce(0) { $0 + $1.totalDuration } ?? 0
                                        return total1 > total2
                                    }), id: \.self) { category in
                                        if let categoryApps = activityReport.categorizedApps[category] {
                                            let categoryTotal = categoryApps.reduce(0) { $0 + $1.totalDuration }
                                            let categoryWidth = (categoryTotal / activityReport.totalScreenTime) * chartWidth
                                            
                                            Rectangle()
                                                .fill(categoryColor(for: category))
                                                .frame(width: max(categoryWidth, 1))
                                        }
                                    }
                                }
                                .frame(height: 32)
                                .cornerRadius(8)
                            }
                            .frame(height: 32)
                            
                            // Category Legend
                            VStack(spacing: 8) {
                                ForEach(Array(activityReport.categorizedApps.keys.sorted { cat1, cat2 in
                                    let total1 = activityReport.categorizedApps[cat1]?.reduce(0) { $0 + $1.totalDuration } ?? 0
                                    let total2 = activityReport.categorizedApps[cat2]?.reduce(0) { $0 + $1.totalDuration } ?? 0
                                    return total1 > total2
                                }), id: \.self) { category in
                                    if let categoryApps = activityReport.categorizedApps[category] {
                                        let categoryTotal = categoryApps.reduce(0) { $0 + $1.totalDuration }
                                        
                                        HStack {
                                            Circle()
                                                .fill(categoryColor(for: category))
                                                .frame(width: 10, height: 10)
                                            
                                            Text(category)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text(formatDuration(categoryTotal))
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Metrics Row
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                
                                Text("Total:")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(formatDuration(activityReport.totalScreenTime))
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Apps Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Apps")
                                .font(.system(size: 17))
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                ForEach(activityReport.apps.prefix(24), id: \.appName) { app in
                                    HStack(spacing: 12) {
                                        // App icon with category color
                                        Circle()
                                            .fill(categoryColor(for: AppUsageInfo.getCategory(for: app.appName)))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(getAppInitial(app.appName))
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(app.appName)
                                            .font(.body)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // Percentage
                                        Text(formatPercentage(app.totalDuration / activityReport.totalScreenTime))
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .monospacedDigit()
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        // Duration
                                        Text(formatDuration(app.totalDuration))
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .frame(width: 70, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    
                                    if app != activityReport.apps.prefix(24).last {
                                        Divider()
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        
        if duration == 0 {
            return "-"
        } else if minutes == 0 && duration > 0 {
            return "<1m"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: duration) ?? "-"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let percentage = value * 100
        if percentage < 1 && percentage > 0 {
            return "<1%"
        } else {
            return "\(Int(percentage))%"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Social":
            return .orange
        case "Entertainment":
            return .purple
        case "Productivity":
            return .blue
        case "Finance":
            return Color(red: 0/255, green: 150/255, blue: 0/255) // Dark green for finance
        case "Digital Wellbeing":
            return Color(red: 75/255, green: 0/255, blue: 130/255) // Indigo/Purple for wellbeing
        case "Education":
            return .teal
        case "Information & Reading":
            return .brown
        case "Creativity":
            return .indigo
        case "Health & Fitness":
            return .pink
        case "Shopping & Food":
            return .green
        case "Travel":
            return .cyan
        case "AI & Assistants":
            return .mint
        case "Other":
            return .gray
        default:
            return .gray
        }
    }
    
    private func getAppInitial(_ appName: String) -> String {
        // Handle known problematic apps
        let knownApps: [String: String] = [
            "whatsapp": "W",
            "chatgpt": "C",
            "youtube music": "Y",
            "tiktok": "T",
            "linkedin": "L"
        ]
        
        let lowerName = appName.lowercased()
        for (key, initial) in knownApps {
            if lowerName.contains(key) {
                return initial
            }
        }
        
        // Remove common prefixes and suffixes
        let cleanName = appName
            .replacingOccurrences(of: " - ", with: " ")
            .replacingOccurrences(of: ": ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle empty or whitespace
        if cleanName.isEmpty {
            // Find first character
            let stripped = appName.filter { !$0.isWhitespace }
            if !stripped.isEmpty {
                return String(stripped.prefix(1)).uppercased()
            }
            return "?"
        }
        
        // Get first alphanumeric character
        for char in cleanName {
            if char.isLetter || char.isNumber {
                return String(char).uppercased()
            }
        }
        
        return "?"
    }
}

#Preview {
    TotalActivityView(
        activityReport: ActivityReportData(
            apps: [
                AppUsageInfo(appName: "Safari", totalDuration: 3600, formattedDuration: "1h"),
                AppUsageInfo(appName: "Instagram", totalDuration: 1800, formattedDuration: "30m"),
                AppUsageInfo(appName: "YouTube", totalDuration: 2700, formattedDuration: "45m")
            ],
            totalScreenTime: 8100
        )
    )
}
