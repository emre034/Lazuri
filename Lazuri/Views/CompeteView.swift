//
//  CompeteView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import SwiftUI
import GameKit

struct CompeteView: View {
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @StateObject private var userDataManager = UserDataManager.shared
    @State private var showingGameCenterLeaderboard = false
    @State private var showingGameCenterAchievements = false
    @State private var showingGameCenterDashboard = false
    @State private var showingMotivationSheet = false
    @State private var showingInfoSection = false
    
    // Motivation question states
    @AppStorage("userMotivation") private var userMotivation = ""
    @State private var isEditingMotivation = false
    @State private var tempMotivationText = ""
    @FocusState private var isTextFieldFocused: Bool
    private let sharedDefaults = UserDefaults(suiteName: "group.com.emrekulaber.Lazuri")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Motivation Button
                    Button(action: {
                        showingMotivationSheet = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            Text(userMotivation.isEmpty ? "Add Your Promises" : "View Your Promises")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if gameCenterManager.isAuthenticated {
                        // MARK: - Game Center Navigation
                        ButtonsGameCenterView(
                        onAllActivity: { showingGameCenterDashboard = true },
                        onLeaderboard: { showingGameCenterLeaderboard = true },
                        onAchievements: { showingGameCenterAchievements = true }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    
                    // MARK: - Original UI (Old implementation)
                    /*
                    Picker("View", selection: $selectedTab) {
                        Text("Leaderboard").tag(0)
                        Text("Achievements").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == 0 {
                        leaderboardView
                    } else {
                        achievementsView
                    }
                    */
                } else {
                    // Not authenticated view
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Connect to Game Center")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Sign in to compete with friends and track your achievements")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            Label("How to Sign In", systemImage: "info.circle.fill")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("1.")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    Text("When you first launch the app, tap the Game Center banner that appears at the top of your screen. If you dismissed it, please restart the app.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Text("2.")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    Text("Alternatively, go to Settings > Game Center and sign in with your Apple ID.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            
                            Button(action: {
                                if let url = URL(string: "App-prefs:") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Open Settings")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Image(systemName: "arrow.up.forward.square")
                                        .font(.caption)
                                }
                                .foregroundColor(Color(.systemBlue))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemBlue).opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        if gameCenterManager.authenticationError != nil {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Game Center authentication failed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Info Button (always visible)
                Button(action: {
                    showingInfoSection = true
                }) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                        Text("About")
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
                .padding(.top, 10)
                
                
                Spacer(minLength: 30)
                }
            }
            .onAppear {
                // Refresh user data from shared defaults
                userDataManager.refreshFromSharedDefaults()
                // print("CompeteView appeared")
            }
            .sheet(isPresented: $showingGameCenterLeaderboard) {
                GameCenterView(viewState: .leaderboards, isPresented: $showingGameCenterLeaderboard)
            }
            .sheet(isPresented: $showingGameCenterAchievements) {
                GameCenterView(viewState: .achievements, isPresented: $showingGameCenterAchievements)
            }
            .sheet(isPresented: $showingGameCenterDashboard) {
                GameCenterView(viewState: .dashboard, isPresented: $showingGameCenterDashboard)
            }
            .sheet(isPresented: $showingMotivationSheet) {
                MotivationSheetView(
                    userMotivation: $userMotivation,
                    isEditingMotivation: $isEditingMotivation,
                    tempMotivationText: $tempMotivationText,
                    isTextFieldFocused: $isTextFieldFocused,
                    sharedDefaults: sharedDefaults
                )
            }
            .sheet(isPresented: $showingInfoSection) {
                VStack(spacing: 20) {
                    Text("About the Logo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("This work (the Georgian Borjgali symbol) is created by George Melashvili. You can redistribute it or modify it under the terms of CC BY-SA 3.0 (See below)")
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(spacing: 4) {
                        Link("საქართველო - Own work, CC BY-SA 3.0", destination: URL(string: "https://commons.wikimedia.org/w/index.php?curid=11381642")!)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                        
                        Link("https://commons.wikimedia.org/w/index.php?curid=11381642", destination: URL(string: "https://commons.wikimedia.org/w/index.php?curid=11381642")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("(The logo has been resized for this application)")
                        .font(.footnote)
                        .foregroundColor(.black)
                        .italic()
                    
                    Text("Application developed by Emre Kulaber")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.4)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    CompeteView()
}
