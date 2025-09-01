//
//  ShieldConfigurationExtension.swift
//  LazuriShieldConfiguration
//
//  Created by Emre Kulaber on 18/07/2025.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Shield configuration extension for customizing blocked app appearance
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri")
    
    private var userMotivation: String {
        sharedDefaults?.string(forKey: "userMotivation") ?? "Write your promises to your future self"
    }
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Georgian Borjgala theme configuration
        
        // Cream background color
        let backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 0.95)
        
        let darkRedColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        
        
        // Red button color
        let vibrantRedColor = UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: backgroundColor,
            icon: UIImage(named: "Borjgala-2-removebg-preview"),
            title: ShieldConfiguration.Label(
                text: "Remember the promises you made to your future self:",
                color: darkRedColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: userMotivation,
                color: .black
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "I won't break my promise!",
                color: .white
            ),
            primaryButtonBackgroundColor: vibrantRedColor
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Apply same configuration for category blocking
        return configuration(shielding: application)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Web domain blocking configuration
        
        // Cream background color
        let backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 0.95)
        
        
        let darkRedColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        
        
        // Red button color
        let vibrantRedColor = UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: backgroundColor,
            icon: UIImage(named: "Borjgala-2-removebg-preview"),
            title: ShieldConfiguration.Label(
                text: "Remember the promises you made to your future self:",
                color: darkRedColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: userMotivation,
                color: .black
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "I won't break my promise!",
                color: .white
            ),
            primaryButtonBackgroundColor: vibrantRedColor
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Apply same configuration for web category blocking
        return configuration(shielding: webDomain)
    }
}
