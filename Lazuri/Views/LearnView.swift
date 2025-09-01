//
//  LearnView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import SwiftUI

struct LearnView: View {
    // TODO: Add bookmark feature for favorite cards
    // IDEA: Swipe animation could be smoother
    @State private var flashcards: [Flashcard] = []
    @State private var filteredFlashcards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var showShareSheet = false
    @State private var shareText = ""
    @AppStorage("viewedCards", store: UserDefaults(suiteName: "group.com.emrekulaber.Lazuri")) private var viewedCardsData = Data()
    @State private var viewedCards: Set<Int> = []
    @State private var isMovingForward = true
    @State private var selectedCategory: String? = nil
    @StateObject private var userDataManager = UserDataManager.shared
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if filteredFlashcards.isEmpty {
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            Image(systemName: selectedCategory != nil ? "tray" : "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text(selectedCategory != nil ? "No Cards in This Category" : "No Flashcards Available")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(selectedCategory != nil ? "Try selecting a different category" : "Unable to load flashcards. Please try again later.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Spacer()
                        
                        // Show tag bar even when filtered empty
                        if !flashcards.isEmpty {
                            tagFilterBar
                                .padding(.bottom, 10)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        // Main content area
                        VStack(spacing: 0) {
                            // Flashcard stack
                            VStack(spacing: 20) {
                                if !filteredFlashcards.isEmpty {
                                    ZStack {
                                        ForEach(filteredFlashcards.indices, id: \.self) { index in
                                            if index == currentIndex {
                                                flashcardView(for: filteredFlashcards[index])
                                                    .offset(dragOffset)
                                                    .gesture(dragGesture)
                                                    .transition(.asymmetric(
                                                        insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
                                                        removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
                                                    ))
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: geometry.size.height * 0.62)
                            
                            // Progress indicator
                            HStack(spacing: 12) {
                                Text("\(currentIndex + 1)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("/")
                                    .foregroundColor(.gray)
                                
                                Text("\(filteredFlashcards.count)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Tag filter bar at bottom
                        tagFilterBar
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .padding(.top) // Safe area for status bar
            .onAppear {
                loadFlashcards()
                loadViewedCards()
                impactFeedback.prepare()
            }
            .sheet(isPresented: $showShareSheet) {
                if let currentCard = filteredFlashcards[safe: currentIndex] {
                    ShareSheet(activityItems: [formatShareText(for: currentCard)])
                }
            }
        }
    }
    
    private var tagFilterBar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                // All tag
                TagPill(title: "All", 
                       isSelected: selectedCategory == nil,
                       action: {
                           withAnimation(.spring()) {
                               selectedCategory = nil
                               currentIndex = 0
                               filterCards()
                           }
                       })
                
                // Category tags
                ForEach(uniqueCategories, id: \.self) { category in
                    TagPill(title: category,
                           isSelected: selectedCategory == category,
                           action: {
                               withAnimation(.spring()) {
                                   selectedCategory = category
                                   currentIndex = 0
                                   filterCards()
                               }
                           })
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 240)
        .background(Color(.systemBackground))
    }
    
    private var uniqueCategories: [String] {
        Array(Set(flashcards.map { $0.category })).sorted()
    }
    
    private func flashcardView(for card: Flashcard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category pill
            Text(card.category)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(15)
            
            // Title
            Text(card.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Content
            Text(card.content)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            markCardAsViewed(card.id)
        }
        .onTapGesture {
            if let urlString = card.link, 
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let verticalThreshold: CGFloat = 150
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if value.translation.width > threshold {
                        // Swipe right - previous card
                        isMovingForward = false
                        previousCard()
                        impactFeedback.impactOccurred()
                        trackCardView()
                    } else if value.translation.width < -threshold {
                        // Swipe left - next card
                        isMovingForward = true
                        nextCard()
                        impactFeedback.impactOccurred()
                        trackCardView()
                    } else if value.translation.height < -verticalThreshold {
                        // Swipe up - share
                        shareCard()
                        impactFeedback.impactOccurred()
                    }
                    dragOffset = .zero
                }
            }
    }
    
    private func nextCard() {
        guard !filteredFlashcards.isEmpty else { return }
        withAnimation(.spring()) {
            currentIndex = (currentIndex + 1) % filteredFlashcards.count
        }
    }
    
    private func previousCard() {
        guard !filteredFlashcards.isEmpty else { return }
        withAnimation(.spring()) {
            currentIndex = currentIndex == 0 ? filteredFlashcards.count - 1 : currentIndex - 1
        }
    }
    
    private func shareCard() {
        dragOffset = .zero
        showShareSheet = true
    }
    
    private func formatShareText(for card: Flashcard) -> String {
        return """
        \(card.title)
        
        \(card.content)
        
        Category: \(card.category)
        
        Shared from Lazuri App
        """
    }
    
    private func loadFlashcards() {
        flashcards = DataLoader.loadFlashcards()
        filterCards()
    }
    
    private func filterCards() {
        if let category = selectedCategory {
            filteredFlashcards = flashcards.filter { $0.category == category }
        } else {
            filteredFlashcards = flashcards
        }
        
        // Reset index if it's out of bounds
        if currentIndex >= filteredFlashcards.count && !filteredFlashcards.isEmpty {
            currentIndex = 0
        }
    }
    
    private func loadViewedCards() {
        if let decoded = try? JSONDecoder().decode(Set<Int>.self, from: viewedCardsData) {
            viewedCards = decoded
        }
    }
    
    private func saveViewedCards() {
        if let encoded = try? JSONEncoder().encode(viewedCards) {
            viewedCardsData = encoded
        }
    }
    
    private func markCardAsViewed(_ cardId: Int) {
        // Check if this card was already viewed before
        let wasNewCard = !viewedCards.contains(cardId)
        
        print("markCardAsViewed:")
        print("Card ID: \(cardId)")
        print("Was new card: \(wasNewCard)")
        print("Viewed cards count before: \(viewedCards.count)")
        print("Total flashcards viewed before: \(userDataManager.totalFlashcardsViewed)")
        
        viewedCards.insert(cardId)
        saveViewedCards()
        
        // Only increment counter for newly viewed cards
        if wasNewCard {
            userDataManager.incrementFlashcardCount()
            print("Incremented total count")
        } else {
            print("Card already viewed, not incrementing")
        }
        
        print("Viewed cards count after: \(viewedCards.count)")
        print("Total flashcards viewed after: \(userDataManager.totalFlashcardsViewed)")
    }
    
    private func trackCardView() {
        if let currentCard = filteredFlashcards[safe: currentIndex] {
            markCardAsViewed(currentCard.id)
        }
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Tag pill component
struct TagPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color(.systemGray3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ShareSheet wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        // Allow all compatible sharing options
        activityVC.excludedActivityTypes = []
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LearnView()
}
