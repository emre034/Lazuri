//
//  ShieldActionExtension.swift
//  LazuriShieldAction
//
//  Created by Emre Kulaber on 18/07/2025.
//

import ManagedSettings
import UserNotifications

// Shield action extension for handling blocked app interactions
class ShieldActionExtension: ShieldActionDelegate {
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri")
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Process shield action
        switch action {
        case .primaryButtonPressed:
            // Get users motivation text
            let userMotivation = sharedDefaults?.string(forKey: "userMotivation") ?? "Stay focused on your goals!"
            
            // Send motivational notification
            let content = UNMutableNotificationContent()
            content.title = "Note to self:"
            content.body = userMotivation
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error sending notification: \(error)")
                }
            }
            
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            fatalError()
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Process web domain shield action
        completionHandler(.close)
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Process category shield action
        switch action {
        case .primaryButtonPressed:
            // Get users motivation text
            let userMotivation = sharedDefaults?.string(forKey: "userMotivation") ?? "Stay focused on your goals!"
            
            // Send motivational notification
            let content = UNMutableNotificationContent()
            content.title = "Note to self:"
            content.body = userMotivation
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error sending notification: \(error)")
                }
            }
            
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            fatalError()
        }
    }
}
