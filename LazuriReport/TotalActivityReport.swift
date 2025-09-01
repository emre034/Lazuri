//
//  TotalActivityReport.swift
//  LazuriReport
//
//  Created by Emre Kulaber on 08/07/2025.
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReportData) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReportData {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        
        var appUsageData: [AppUsageInfo] = []
        
        // Process data from each device
        for await deviceData in data {
            // Process each activity segment
            for await segment in deviceData.activitySegments {
                // Process each category
                for await category in segment.categories {
                    // Process each application
                    for await application in category.applications {
                        let appName = application.application.localizedDisplayName ?? "Unknown App"
                        let duration = application.totalActivityDuration
                        
                        if let existingIndex = appUsageData.firstIndex(where: { $0.appName == appName }) {
                            appUsageData[existingIndex].totalDuration += duration
                        } else {
                            appUsageData.append(AppUsageInfo(
                                appName: appName,
                                totalDuration: duration,
                                formattedDuration: formatter.string(from: duration) ?? "0m"
                            ))
                        }
                    }
                }
            }
        }
        
        // Sort by duration and update formatted durations
        appUsageData.sort { $0.totalDuration > $1.totalDuration }
        appUsageData = appUsageData.map { info in
            var updatedInfo = info
            updatedInfo.formattedDuration = formatter.string(from: info.totalDuration) ?? "0m"
            return updatedInfo
        }
        
        // DeviceActivityReport extensions cannot write to UserDefaults
        
        return ActivityReportData(
            apps: appUsageData,
            totalScreenTime: appUsageData.reduce(0) { $0 + $1.totalDuration }
        )
    }
}

// MARK: - Data Models
struct ActivityReportData {
    let apps: [AppUsageInfo]
    let totalScreenTime: TimeInterval
    let categorizedApps: [String: [AppUsageInfo]]
    
    init(apps: [AppUsageInfo], totalScreenTime: TimeInterval) {
        self.apps = apps
        self.totalScreenTime = totalScreenTime
        
        // Categorize apps
        var categories: [String: [AppUsageInfo]] = [:]
        
        for app in apps {
            let category = AppUsageInfo.getCategory(for: app.appName)
            if categories[category] == nil {
                categories[category] = []
            }
            categories[category]?.append(app)
        }
        
        self.categorizedApps = categories
    }
}

struct AppUsageInfo: Equatable {
    let appName: String
    var totalDuration: TimeInterval
    var formattedDuration: String
    
    static func getCategory(for appName: String) -> String {
        let lowercasedName = appName.lowercased()
        
        // Digital Wellbeing
        if ["lazuri", "screen time", "screentime", "moment", "forest", "flora", "focus keeper", "focuskeeper", "be focused", "freedom", "rescuetime", "stay focused", "offtime", "space", "flipd", "zen", "detox", "one sec", "onesec", "clearspace", "clear space"].contains(where: lowercasedName.contains) {
            return "Digital Wellbeing"
        }
        
        // AI & Assistants
        if ["chatgpt", "chat gpt", "openai", "claude", "anthropic", "gemini", "bard", "perplexity", "copilot", "github copilot", "midjourney", "dall-e", "stable diffusion", "character.ai", "replika", "pi", "poe", "jasper", "writesonic", "copy.ai", "notion ai", "grammarly", "quillbot", "otter", "descript", "runway", "eleven labs", "elevenlabs", "synthesia", "heygen", "d-id", "luma", "leonardo", "ideogram", "flux", "grok", "meta ai", "llama", "mistral", "hugging face", "huggingface"].contains(where: lowercasedName.contains) {
            return "AI & Assistants"
        }
        
        // Social apps
        if ["whatsapp", "instagram", "facebook", "twitter", "x", "telegram", "signal", "discord", "snapchat", "tiktok", "linkedin", "reddit", "pinterest", "tumblr", "wechat", "line", "viber", "messenger", "skype", "zoom", "teams", "slack"].contains(where: lowercasedName.contains) {
            return "Social"
        }
        
        // Entertainment (YouTube moved here)
        if ["youtube", "netflix", "hulu", "disney", "prime video", "hbo", "apple tv", "spotify", "apple music", "music", "pandora", "soundcloud", "audible", "podcasts", "podcast", "twitch", "games", "gaming", "tv", "video"].contains(where: lowercasedName.contains) {
            return "Entertainment"
        }
        
        // Productivity
        if ["safari", "chrome", "firefox", "edge", "notes", "reminders", "calendar", "mail", "gmail", "outlook", "notion", "obsidian", "evernote", "todoist", "things", "omnifocus", "bear", "drafts", "pages", "numbers", "keynote", "word", "excel", "powerpoint", "google docs", "sheets", "slides", "finder", "files", "dropbox", "drive", "onedrive", "icloud", "calculator"].contains(where: lowercasedName.contains) {
            return "Productivity"
        }
        
        // Finance
        if ["stocks", "wallet", "pay", "venmo", "paypal", "cash", "banking", "bank", "trading", "robinhood", "coinbase", "mint", "quickbooks", "finance", "zelle", "wise", "revolut", "monzo", "n26", "chime", "sofi", "etrade", "fidelity", "schwab", "vanguard", "acorns", "stash", "betterment", "wealthfront", "personal capital", "ynab", "pocketguard", "truebill", "clarity money", "prism", "mobills", "money lover", "spendee", "goodbudget", "monefy", "wallet by budgetbakers", "toshl", "copilot money", "monarch", "simplifi"].contains(where: lowercasedName.contains) {
            return "Finance"
        }
        
        // Shopping & Food
        if ["amazon", "ebay", "aliexpress", "walmart", "target", "best buy", "etsy", "shop", "shopping", "store", "uber eats", "doordash", "grubhub", "postmates", "deliveroo", "zomato", "swiggy"].contains(where: lowercasedName.contains) {
            return "Shopping & Food"
        }
        
        // Education
        if ["books", "kindle", "coursera", "udemy", "khan academy", "duolingo", "learning", "education", "study", "quizlet", "brilliant", "skillshare"].contains(where: lowercasedName.contains) {
            return "Education"
        }
        
        // Information & Reading
        if ["news", "apple news", "google news", "flipboard", "feedly", "medium", "wikipedia", "quora", "weather", "reddit"].contains(where: lowercasedName.contains) {
            return "Information & Reading"
        }
        
        // Creativity
        if ["photos", "camera", "vsco", "lightroom", "photoshop", "canva", "procreate", "garageband", "imovie", "final cut", "premiere", "sketch", "figma", "pinterest"].contains(where: lowercasedName.contains) {
            return "Creativity"
        }
        
        // Health & Fitness
        if ["health", "fitness", "workout", "exercise", "meditation", "calm", "headspace", "strava", "nike", "adidas", "peloton", "myfitnesspal", "fitbit", "sleep"].contains(where: lowercasedName.contains) {
            return "Health & Fitness"
        }
        
        // Travel
        if ["maps", "apple maps", "google maps", "waze", "uber", "lyft", "airbnb", "booking", "expedia", "tripadvisor", "yelp"].contains(where: lowercasedName.contains) {
            return "Travel"
        }
        
        // Default category
        return "Other"
    }
}