//
//  AddPantryItemView.swift
//  Zipack
//
//  Created by Tutu on 7/12/25.
//

import SwiftUI

struct AddPantryItemView: View {
    @ObservedObject var pantryVM: PantryViewModel // Observe the PantryViewModel
    @Binding var isShowingSheet: Bool // Binding to dismiss the sheet

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add New Pantry Item").font(.headline)) {
                    TextField("Ingredient Name", text: $pantryVM.newPantryItemName)
                    // DatePicker for expiration date
                    DatePicker("Expiration Date (Optional)", selection: $pantryVM.newPantryItemExpiration, displayedComponents: .date)
                }
                
                // Add Item Button
                Button("Add Item") {
                    pantryVM.addPantryItem()
                    isShowingSheet = false // Dismiss the sheet after adding
                }
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
                .listRowBackground(Color.clear) // Make button background transparent in form
                
                // Display error message if any
                if let errorMessage = pantryVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add Pantry Item")
            .toolbar {
                // Cancel button in toolbar
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isShowingSheet = false
                    }
                }
            }
        }
    }
}
