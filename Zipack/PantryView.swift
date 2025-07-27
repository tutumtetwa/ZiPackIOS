//
//  PantryView.swift
//  Zipack
//
//  Created by Tutu on 7/12/25.
//

import SwiftUI

struct PantryView: View {
    // Access PantryViewModel via EnvironmentObject
    @EnvironmentObject var pantryVM: PantryViewModel
    @State private var showingAddPantryItemSheet = false // State to control sheet presentation

    var body: some View {
        NavigationView {
            VStack {
                if pantryVM.isLoading {
                    ProgressView("Loading Pantry...") // Show loading indicator
                } else if let errorMessage = pantryVM.errorMessage {
                    Text("Error: \(errorMessage)") // Display error message
                        .foregroundColor(.red)
                } else if pantryVM.pantryItems.isEmpty {
                    // ContentUnavailableView for empty state (iOS 17+)
                    ContentUnavailableView("No Pantry Items", systemImage: "carrot.fill", description: Text("Add ingredients to your pantry to get started!"))
                } else {
                    List {
                        // Display each pantry item
                        ForEach(pantryVM.pantryItems) { item in
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                
                                // Display expiration date and status
                                if let expDateString = item.expirationDate,
                                   let expDate = ISO8601DateFormatter().date(from: expDateString) {
                                    let today = Date()
                                    let calendar = Calendar.current
                                    let diffDays = calendar.dateComponents([.day], from: today, to: expDate).day ?? 0
                                    
                                    if expDate < today {
                                        Text("Expired")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.red)
                                            .cornerRadius(5)
                                    } else if diffDays <= 7 {
                                        Text("Exp. \(expDate.formatted(date: .numeric, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.orange)
                                            .cornerRadius(5)
                                    } else {
                                        Text("Exp. \(expDate.formatted(date: .numeric, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                            }
                            // Swipe to delete functionality
                            .swipeActions {
                                Button(role: .destructive) {
                                    pantryVM.removePantryItem(item: item)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Your Pantry")
            .toolbar {
                // Toolbar button to add new pantry item
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPantryItemSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("AccentColor")) // Custom accent color
                    }
                }
            }
            // Sheet for adding new pantry item
            .sheet(isPresented: $showingAddPantryItemSheet) {
                AddPantryItemView(pantryVM: pantryVM, isShowingSheet: $showingAddPantryItemSheet)
            }
        }
    }
}
