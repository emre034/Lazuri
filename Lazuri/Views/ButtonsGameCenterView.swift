//
//  ButtonsGameCenterView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 15/07/2025.
//

import SwiftUI

struct ButtonsGameCenterView: View {
    let onAllActivity: () -> Void
    let onLeaderboard: () -> Void
    let onAchievements: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // All Activity Card
            Button(action: onAllActivity) {
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("All Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.blue)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Leaderboard Card
            Button(action: onLeaderboard) {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("Leaderboard")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.orange)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Achievements Card
            Button(action: onAchievements) {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("Achievements")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.green)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }
}

#Preview {
    ButtonsGameCenterView(
        onAllActivity: {},
        onLeaderboard: {},
        onAchievements: {}
    )
    .frame(width: 300, height: 400)
}
