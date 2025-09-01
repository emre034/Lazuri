# Lazuri - Digital Wellbeing & Focus Management App

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)

## Overview

Lazuri is an innovative iOS application developed as part of an MSc Computer Science thesis project, designed to help users manage their digital wellbeing through intelligent screen time monitoring, focus sessions, and gamified learning experiences. The app combines Apple's Screen Time API with educational content and competitive elements to create a comprehensive digital wellness solution.

## 🎯 Core Features

### 📱 Smart Focus Management
- **Adaptive Scheduling**: Create custom focus schedules with app blocking capabilities
- **Real-time Monitoring**: Track screen time usage with detailed analytics and charts
- **Shield Protection**: Automatic app blocking during scheduled focus periods
- **Activity Tracking**: Monitor device usage patterns and receive insights

### 📚 Interactive Learning System
- **Smart Flashcards**: Swipe-based learning interface with categorized educational content
- **Progress Tracking**: Monitor learning progress with visual indicators
- **Category Filtering**: Organize and filter content by topics
- **Social Sharing**: Share achievements and learning milestones

### 🏆 Gamification & Competition
- **Game Center Integration**: Compete with friends on focus achievements
- **Leaderboards**: Global and friend rankings for motivation
- **Achievement System**: Unlock badges for reaching focus milestones
- **Personal Goals**: Set and track custom motivation promises

### 📊 Analytics Dashboard
- **Usage Charts**: Interactive visualizations of screen time data
- **Weekly/Monthly Views**: Comprehensive time period analysis
- **Focus Metrics**: Track saved time and productivity gains
- **Historical Data**: Review past performance and improvements

## 🛠 Technical Architecture

### Frameworks & Technologies
- **SwiftUI**: Modern declarative UI framework
- **FamilyControls**: Apple's Screen Time API integration
- **DeviceActivity**: Background activity monitoring
- **GameKit**: Game Center services
- **Charts**: Native chart rendering
- **UserNotifications**: Smart notification system

### Extensions
- **Device Activity Monitor**: Background monitoring extension
- **Shield Configuration**: Custom shield UI for blocked apps
- **Shield Action**: Handle user interactions with shields
- **Activity Report**: Generate detailed usage reports

### Data Management
- **App Groups**: Shared data between app and extensions
- **UserDefaults**: Persistent storage with suite configuration
- **Codable Models**: Type-safe data serialization
- **Singleton Managers**: Centralized service management

## 📋 Requirements

- **iOS 17.0+** / iPadOS 17.0+
- **Xcode 15.0+**
- **Swift 5.9+**
- **Screen Time permissions** enabled
- **Game Center account** (optional for competitive features)

## 🚀 Installation

1. Clone the repository:
```bash
git clone https://github.com/emre034/Lazuri.git
```

2. Open the project in Xcode:
```bash
cd Lazuri
open Lazuri.xcodeproj
```

3. Configure signing:
   - Select your development team in project settings
   - Update bundle identifiers if needed
   - Ensure all app extensions are properly configured

4. Enable required capabilities:
   - Family Controls
   - App Groups
   - Game Center
   - Push Notifications

5. Build and run on your device (Screen Time APIs require physical device)

## 🏗 Project Structure

```
Lazuri/
├── App/
│   ├── LazuriApp.swift         # App entry point
│   └── ContentView.swift       # Main navigation
├── Views/
│   ├── FocusView.swift         # Focus management UI
│   ├── LearnView.swift         # Flashcard system
│   ├── CompeteView.swift       # Game Center integration
│   └── Supporting Views/       # Reusable components
├── Services/
│   ├── ScreenTimeManager.swift # Screen Time API handler
│   ├── GameCenterManager.swift # Game Center services
│   ├── FocusTracker.swift      # Focus session tracking
│   └── UserDataManager.swift   # User data persistence
├── Models/
│   └── Flashcard.swift         # Data models
└── Extensions/
    ├── LazuriMonitor/          # Activity monitoring
    ├── LazuriReport/           # Usage reports
    ├── LazuriShieldAction/     # Shield interactions
    └── LazuriShieldConfiguration/ # Shield UI
```

## 🔒 Privacy & Permissions

Lazuri requires the following permissions:
- **Screen Time**: To monitor and restrict app usage
- **Notifications**: For focus reminders and alerts
- **Game Center**: For competitive features (optional)

All data is stored locally on device using App Groups. No personal data is transmitted to external servers.

## 🎓 Academic Context

This application was developed as part of an MSc Computer Science thesis investigating:
- Digital wellbeing intervention strategies
- Gamification in behavior change applications
- Screen time management effectiveness
- User engagement with focus management tools

## 🤝 Contributing

As this is an academic thesis project currently under evaluation, the repository is private. After thesis completion and approval, contribution guidelines will be established.

## 📄 License

This project is currently under academic evaluation. All rights reserved. Commercial use, modification, and distribution are prohibited without explicit permission.

## 👨‍💻 Author

**Emre Kulaber**  
MSc Computer Science   
[GitHub](https://github.com/emre034)

## 🙏 Acknowledgments

- Apple Developer Documentation for Screen Time API guidance
- SwiftUI community for UI/UX patterns
- Academic supervisors for project guidance
- Beta testers for valuable feedback

---

*Note: This project is part of an ongoing MSc thesis. Full source code access may be restricted until academic evaluation is complete.*
