//
//  Flashcard.swift
//  Lazuri
//
//  Created by Emre Kulaber on 07/07/2025.
//

import Foundation

// Flashcard model
// TODO: Add proper difficulty levels
struct Flashcard: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let category: String
    let link: String? // a link to more info about the topic
    
    // Future fields:
    // var difficulty: Int?
    // var lastViewed: Date?
    // var isFavorite: Bool?
}

// JSON wrapper for flashcard data
struct FlashcardData: Codable {
    let cards: [Flashcard]
}
