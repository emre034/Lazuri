//
//  MotivationSheetView.swift
//  Lazuri
//
//  Created by Emre Kulaber on 19/07/2025.
//

import SwiftUI

struct MotivationSheetView: View {
    @Binding var userMotivation: String
    @Binding var isEditingMotivation: Bool
    @Binding var tempMotivationText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let sharedDefaults: UserDefaults?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Question
                Text("What promises do you make to your future self?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Answer section
                if userMotivation.isEmpty && !isEditingMotivation {
                    // Empty state prompt to add
                    Button(action: {
                        isEditingMotivation = true
                        tempMotivationText = ""
                        isTextFieldFocused = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add your promises")
                                .font(.headline)
                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                } else if isEditingMotivation {
                    // Editing state
                    VStack(spacing: 12) {
                        TextField("Write your promises here...", text: $tempMotivationText, axis: .vertical)
                            .font(.headline)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...5)
                            .focused($isTextFieldFocused)
                            .onChange(of: tempMotivationText) { _, newValue in
                                // Limit to 900 characters for Shield display
                                if newValue.count > 900 {
                                    tempMotivationText = String(newValue.prefix(900))
                                }
                            }
                        
                        Text("\(tempMotivationText.count)/900")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isEditingMotivation = false
                                tempMotivationText = ""
                                isTextFieldFocused = false
                            }
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Button("Save") {
                                let trimmedText = tempMotivationText.trimmingCharacters(in: .whitespacesAndNewlines)
                                userMotivation = trimmedText
                                // Also save to shared defaults for Shield
                                sharedDefaults?.set(trimmedText, forKey: "userMotivation")
                                sharedDefaults?.synchronize()
                                isEditingMotivation = false
                                isTextFieldFocused = false
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .disabled(tempMotivationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // Display saved motivation
                    VStack(alignment: .leading, spacing: 12) {
                        Text(userMotivation)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            isEditingMotivation = true
                            tempMotivationText = userMotivation
                            isTextFieldFocused = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                                .font(.callout)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Your Promises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MotivationSheetView(
        userMotivation: .constant("I want to learn new things and improve myself"),
        isEditingMotivation: .constant(false),
        tempMotivationText: .constant(""),
        isTextFieldFocused: FocusState<Bool>().projectedValue,
        sharedDefaults: nil
    )
}
