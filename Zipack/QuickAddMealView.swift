//
//  QuickAddMealView.swift
//  Zipack
//
//  Created by Tutu on 7/12/25.
//

import SwiftUI

struct QuickAddMealView: View {
    // Access MealLogViewModel via EnvironmentObject
    @EnvironmentObject var mealLogVM: MealLogViewModel

    // State variables for input fields
    @State private var quickAddMealName: String = ""
    @State private var quickAddCalories: String = ""
    @State private var quickAddProtein: String = ""
    @State private var quickAddCarbs: String = ""
    @State private var quickAddFat: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Manual Meal Entry").font(.headline)) {
                    TextField("Meal Name", text: $quickAddMealName)
                    TextField("Calories (kcal)", text: $quickAddCalories)
                        .keyboardType(.numberPad) // Ensure numeric keyboard
                    TextField("Protein (g)", text: $quickAddProtein)
                        .keyboardType(.numberPad)
                    TextField("Carbs (g)", text: $quickAddCarbs)
                        .keyboardType(.numberPad)
                    TextField("Fat (g)", text: $quickAddFat)
                        .keyboardType(.numberPad)
                }

                // Log Manual Meal Button
                Button("Log Manual Meal") {
                    // Call ViewModel function to add meal
                    mealLogVM.quickAddMeal(
                        name: quickAddMealName,
                        calories: Int(quickAddCalories) ?? 0, // Convert string to Int
                        protein: Int(quickAddProtein) ?? 0,
                        carbs: Int(quickAddCarbs) ?? 0,
                        fat: Int(quickAddFat) ?? 0
                    )
                    // Clear input fields after logging
                    quickAddMealName = ""
                    quickAddCalories = ""
                    quickAddProtein = ""
                    quickAddCarbs = ""
                    quickAddFat = ""
                }
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange]), startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
                .listRowBackground(Color.clear) // Make button background transparent in form

                // Display error message from ViewModel
                if let errorMessage = mealLogVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Quick Add Meal")
        }
    }
}
