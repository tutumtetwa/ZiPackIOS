
import SwiftUI

struct RecipeGenerationView: View {
    // Access ViewModels via EnvironmentObject as they are provided by the App struct
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var pantryVM: PantryViewModel
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @EnvironmentObject var recipeGenVM: RecipeGenerationViewModel // The main RecipeGenerationViewModel

    // State variables for user inputs on this view
    @State private var cuisinePreference: String = ""
    @State private var mealType: String = "dinner"
    @State private var cookingTime: String = ""
    @State private var servings: Int = 1
    @State private var excludedIngredients: String = ""
    @State private var includedIngredients: String = ""
    @State private var spiceLevel: String = "mild"
    @State private var cookingMethod: String = "any"
    @State private var mealPrepFocus: Bool = false
    @State private var showAdvancedOptions: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Generate Personalized Recipe")
                        .font(.largeTitle).bold()
                        .foregroundColor(Color("AccentColor"))
                        .padding(.bottom, 10)

                    // Section for Recipe Preferences
                    SectionView(title: "Recipe Preferences", icon: Image(systemName: "slider.horizontal.3")) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Cuisine Preference (e.g., Italian, Mexican)", text: $cuisinePreference)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Picker("Meal Type", selection: $mealType) {
                                Text("Breakfast").tag("breakfast")
                                Text("Lunch").tag("lunch")
                                Text("Dinner").tag("dinner")
                                Text("Snack").tag("snack")
                            }
                            .pickerStyle(.segmented)
                            TextField("Cooking Time (minutes)", text: $cookingTime)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Stepper(value: $servings, in: 1...10) {
                                Text("Servings: \(servings)")
                            }
                            .padding(.vertical, 5)

                            Toggle(isOn: $showAdvancedOptions.animation()) {
                                Text("Show Advanced Options")
                            }
                            .padding(.vertical, 5)

                            if showAdvancedOptions {
                                VStack(alignment: .leading, spacing: 10) {
                                    TextField("Exclude Ingredients (comma-separated)", text: $excludedIngredients)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    TextField("Include Ingredients (comma-separated)", text: $includedIngredients)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Picker("Spice Level", selection: $spiceLevel) {
                                        Text("Mild").tag("mild")
                                        Text("Medium").tag("medium")
                                        Text("Spicy").tag("spicy")
                                    }
                                    .pickerStyle(.segmented)

                                    Picker("Cooking Method", selection: $cookingMethod) {
                                        Text("Any").tag("any")
                                        Text("Oven").tag("oven")
                                        Text("Stovetop").tag("stovetop")
                                        Text("Slow Cooker").tag("slow_cooker")
                                        Text("Instant Pot").tag("instant_pot")
                                        Text("Grill").tag("grill")
                                    }
                                    .pickerStyle(.menu)

                                    Toggle(isOn: $mealPrepFocus) {
                                        Text("Focus on Meal Prep (makes larger batches)")
                                    }
                                }
                                .padding(.top, 10)
                                .transition(.slide)
                            }
                        }
                    }

                    Button {
                        Task {
                            await recipeGenVM.generateRecipe(
                                cuisinePreference: cuisinePreference,
                                mealType: mealType,
                                cookingTime: cookingTime,
                                servings: servings,
                                excludedIngredients: excludedIngredients,
                                includedIngredients: includedIngredients,
                                spiceLevel: spiceLevel,
                                cookingMethod: cookingMethod,
                                mealPrepFocus: mealPrepFocus,
                                refine: false
                            )
                        }
                    } label: {
                        Label(recipeGenVM.isLoading ? "Generating..." : "Generate Personalized Recipe", systemImage: "sparkles")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.orange]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .disabled(recipeGenVM.isLoading || profileVM.userProfile.calorieTarget == 0)
                    .padding(.horizontal)

                    // NEW: Display error/success message from RecipeGenerationViewModel
                    if let message = recipeGenVM.errorMessage {
                        Text(message)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    // NEW: Display error/success message from MealLogViewModel (for logging)
                    if let message = mealLogVM.errorMessage {
                        Text(message)
                            .foregroundColor(message.contains("success") ? .green : .red) // Green for success, red for error
                            .padding(.horizontal)
                    }


                    if let recipe = recipeGenVM.generatedRecipe {
                        RecipeCardView(recipe: recipe)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Generate Recipe")
            .navigationBarHidden(true)
        }
    }
}
