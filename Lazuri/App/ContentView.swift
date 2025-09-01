//
//  ContentView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import SwiftUI

struct ContentView: View {
    // Main tab view controller
    
    var body: some View {
        TabView {
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
            
            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "hourglass")
                }
            
            CompeteView()
                .tabItem {
                    Label("Compete", systemImage: "trophy.fill")
                }
        }
         
    }
}

// Preview
#Preview {
    ContentView()
}
