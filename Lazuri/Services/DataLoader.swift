//
//  DataLoader.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import Foundation

class DataLoader {
    // TODO: Add support for loading flashcards from a remote server (do research about integrating remote server after dissertation)
    // FIXME: No error reporting to user when load fails
    
    static func loadFlashcards() -> [Flashcard] {
        // Load flashcards from local JSON file
        guard let url = Bundle.main.url(forResource: "flashcards", withExtension: "json") else {
            // Failed to find flashcards.json returning empty array
            // print("Warning: flashcards.json not found")
            return [] // Return empty array if file not found
        }
        
        do {
            let data = try Data(contentsOf: url) // Synchronous read
            let flashcardData = try JSONDecoder().decode(FlashcardData.self, from: data)
            // print("Loaded \(flashcardData.cards.count) cards")
            return flashcardData.cards
        } catch {
            // Failed to load flashcards - returning empty array
            // print("Decode error: \(error)")
            return [] // Return empty array on decode error
        }
    }
}
