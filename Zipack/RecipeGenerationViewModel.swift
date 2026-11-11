// MARK: - RecipeGenerationViewModel.swift
//
//  RecipeGenerationViewModel.swift
//  AI Personal Chef & Meal Planner
//
//  Created by Gemini AI on 2025-07-12.
//

import Foundation
import FirebaseFirestore
import FirebaseAI
import Combine

// Assuming NATIVE_APP_ID is defined globally or in FirebaseManager.swift
// For example:
// let NATIVE_APP_ID = "com.ai.personalchef"

// Assuming the String extension for jsonEscaped() is available globally
// e.g., in a separate file like Extensions.swift:
// extension String {
//     func jsonEscaped() -> String {
//         return self.replacingOccurrences(of: "\\", with: "\\\\")
//                    .replacingOccurrences(of: "\"", with: "\\\"")
//                    .replacingOccurrences(of: "\n", with: "\\n")
//                    .replacingOccurrences(of: "\t", with: "\\t")
//     }
// }

@MainActor // Mark the entire class to run on the main actor
class RecipeGenerationViewModel: ObservableObject {
    @Published var generatedRecipe: GeneratedRecipe?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? // For errors specific to generation/feedback
    @Published var recipeRating: Int = 0
    @Published var recipeFeedback: String = ""
    @Published var favoriteRecipes: [GeneratedRecipe] = [] // NEW: List of favorited recipes
    @Published var dailyMealPlan: DailyMealPlan? // NEW: Generated daily meal plan

    private var db: Firestore { FirebaseManager.shared.db }
    private var userId: String? { FirebaseManager.shared.userId }
    private var cancellables = Set<AnyCancellable>()

    // Gemini via Firebase AI Logic: requests go through the Firebase project, so no API key ships in the app.
    private lazy var model: GenerativeModel = FirebaseAI.firebaseAI(backend: .googleAI()).generativeModel(
        modelName: "gemini-2.5-flash",
        generationConfig: GenerationConfig(temperature: 0.8, responseMIMEType: "application/json")
    )

    /// Sends a prompt to Gemini and returns the JSON response body.
    private func generateJSON(_ prompt: String) async throws -> Data {
        let response = try await model.generateContent(prompt + "\n\nReturn only the JSON object. All numeric fields must be whole integers.")
        guard let text = response.text, let data = text.data(using: .utf8) else {
            throw NSError(domain: "Zipack.Gemini", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gemini returned an empty response."])
        }
        return data
    }

    // Dependencies (View Models that provide data needed for recipe generation)
    @Published var profileViewModel: ProfileViewModel
    @Published var pantryViewModel: PantryViewModel
    @Published var mealLogViewModel: MealLogViewModel

    init(profileViewModel: ProfileViewModel, pantryViewModel: PantryViewModel, mealLogViewModel: MealLogViewModel) {
        self.profileViewModel = profileViewModel
        self.pantryViewModel = pantryViewModel
        self.mealLogViewModel = mealLogViewModel
        setupFavoriteRecipesListener() // NEW: Listen for favorite recipes
    }
    
    // NEW: Listener for favorite recipes
    private func setupFavoriteRecipesListener() {
        FirebaseManager.shared.$isAuthReady
            .filter { $0 }
            .compactMap { _ in FirebaseManager.shared.userId }
            .sink { [weak self] uid in
                guard let self = self else { return }
                self.db.collection("artifacts/\(NATIVE_APP_ID)/users/\(uid)/favoriteRecipes")
                    .addSnapshotListener { querySnapshot, error in
                        DispatchQueue.main.async { // Ensure updates on main thread
                            if let error = error {
                                print("Error fetching favorite recipes: \(error.localizedDescription)")
                                return
                            }
                            self.favoriteRecipes = querySnapshot?.documents.compactMap { document in
                                try? document.data(as: GeneratedRecipe.self) // Assuming GeneratedRecipe is Codable
                            } ?? []
                            // Update the isFavorite status of the currently generated recipe if it's in favorites
                            if let currentRecipe = self.generatedRecipe {
                                self.generatedRecipe?.isFavorite = self.favoriteRecipes.contains(where: { $0.id == currentRecipe.id })
                            }
                        }
                    }
            }
            .store(in: &cancellables)
    }
    
    func submitRecipeFeedback() {
        guard let recipe = generatedRecipe, !recipeFeedback.isEmpty || recipeRating > 0 else {
            errorMessage = "Please provide a rating or feedback before submitting."
            return
        }
        
        // Save feedback to Firestore
        let feedbackData: [String: Any] = [
            "recipeId": recipe.id,
            "rating": recipeRating,
            "feedback": recipeFeedback,
            "timestamp": Timestamp(date: Date())
        ]
        
        guard let userId = userId else {
            errorMessage = "User not authenticated."
            return
        }
        
        do {
            try db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/feedback")
                .addDocument(data: feedbackData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
                        } else {
                            self.errorMessage = "Feedback submitted successfully!"
                            self.recipeRating = 0
                            self.recipeFeedback = ""
                        }
                    }
                }
        } catch {
            errorMessage = "Error encoding feedback: \(error.localizedDescription)"
        }
    }

    // Generates a personalised recipe with Gemini
    func generateRecipe(
        cuisinePreference: String,
        mealType: String,
        cookingTime: String,
        servings: Int,
        excludedIngredients: String,
        includedIngredients: String,
        spiceLevel: String,
        cookingMethod: String,
        mealPrepFocus: Bool,
        refine: Bool = false
    ) async {
        if !FirebaseManager.shared.isAuthReady || FirebaseManager.shared.userId == nil {
            errorMessage = "App not ready. Please wait for authentication to complete."
            return
        }
        // No need for `let userId = FirebaseManager.shared.userId!` here, as it's part of the class `userId` property.

        guard profileViewModel.userProfile.calorieTarget > 0 else {
            errorMessage = "Please save your user settings (weight, height, age, goal) first to calculate calorie targets."
            return
        }

        isLoading = true
        errorMessage = nil
        generatedRecipe = nil
        recipeRating = 0
        recipeFeedback = ""

        let expiringPantryItems = pantryViewModel.getExpiringPantryItems().map { $0.name }.joined(separator: ", ")
        let pantryList = pantryViewModel.pantryItems.map { $0.name }.joined(separator: ", ")
        let currentConsumedCalories = mealLogViewModel.dailyConsumedCalories
        let remainingCalories = profileViewModel.userProfile.calorieTarget - currentConsumedCalories

        var prompt = """
            You are an AI-powered personal chef. Generate a single recipe in JSON format.
            The recipe should be for a \(mealType) meal.
            Consider the following:
            - User Profile: Age \(profileViewModel.userProfile.age), Gender \(profileViewModel.userProfile.gender), Activity Level \(profileViewModel.userProfile.activityLevel).
            - Weight Goal: \(profileViewModel.userProfile.goal) weight.
            - Nutritional Targets: The recipe should help the user reach their daily target of \(profileViewModel.userProfile.calorieTarget) calories, with current consumed calories today being \(currentConsumedCalories). Focus on making this meal contribute to the remaining \(remainingCalories) calories.
              * Target Protein: \(profileViewModel.userProfile.proteinTarget)g
              * Target Carbs: \(profileViewModel.userProfile.carbTarget)g
              * Target Fat: \(profileViewModel.userProfile.fatTarget)g
            - Available Pantry Items: \(pantryList).
            - PRIORITY: If available, strongly prioritize using these expiring items: \(expiringPantryItems.isEmpty ? "None" : expiringPantryItems).
            - Cuisine Preference: \(cuisinePreference.isEmpty ? "any" : cuisinePreference).
            - Cooking Time: Aim for around \(cookingTime.isEmpty ? "45" : cookingTime) minutes.
            - Dietary Restrictions: \(profileViewModel.userProfile.dietaryRestrictions.isEmpty ? "None" : profileViewModel.userProfile.dietaryRestrictions). Ensure the recipe strictly adheres to these.
            - Number of Servings: \(servings)
            - Excluded Ingredients: \(excludedIngredients.isEmpty ? "None" : excludedIngredients)
            - Included Ingredients: \(includedIngredients.isEmpty ? "None" : includedIngredients)
            - Spice Level: \(spiceLevel)
            - Cooking Method: \(cookingMethod.isEmpty ? "any" : cookingMethod)
            - Meal Prep Focus: \(mealPrepFocus ? "Yes, optimize for larger batches and reheatability." : "No, focus on single meal.")

            IMPORTANT: The output MUST be a valid JSON object with the following structure. Ensure 'ingredients' is an array of strings, and 'instructions' is an array of strings.
            {
              "recipeName": "string",
              "description": "string",
              "prepTimeMinutes": number,
              "cookTimeMinutes": number,
              "servings": number,
              "ingredients": ["string", "string", ...],
              "instructions": ["string", "string", ...],
              "nutritionalInfo": {
                "calories": number,
                "proteinGrams": number,
                "carbsGrams": number,
                "fatGrams": number
              },
              "notes": "string"
            }
            """

        if refine {
            prompt += """
            \n**Refinement Request:** The previous recipe was "\(generatedRecipe?.recipeName ?? "an earlier recipe")". Please provide an alternative or refined version based on the same criteria, perhaps with a different approach or ingredient focus.
            """
        }

        do {
            let jsonData = try await generateJSON(prompt)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase // Use this if your API response keys are snake_case

            var recipe = try decoder.decode(GeneratedRecipe.self, from: jsonData) // Decode from Data
            
            // NEW: Check if this recipe is already favorited by the user
            recipe.isFavorite = favoriteRecipes.contains(where: { $0.id == recipe.id })
            // NEW: Check if this recipe (by its generated ID) is already logged today
            recipe.isLoggedToday = mealLogViewModel.isRecipeLoggedToday(recipeId: recipe.id)

            self.generatedRecipe = recipe
            print("Generated recipe: \(recipe.recipeName)")
            self.errorMessage = nil

        } catch {
            self.errorMessage = "Failed to generate recipe: \(error.localizedDescription)"
            print(self.errorMessage!)
        }
        isLoading = false
    }
    
    // NEW: Toggle favorite status for a recipe
    func toggleFavorite(recipe: GeneratedRecipe) {
        guard let userId = userId else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Optimistically update UI
        if let currentRecipe = generatedRecipe, currentRecipe.id == recipe.id {
            generatedRecipe?.isFavorite?.toggle()
        }
        
        // Also update the list of favoriteRecipes and Firestore
        if favoriteRecipes.contains(where: { $0.id == recipe.id }) {
            // It's currently favorited, so remove it
            removeRecipeFromFavorites(recipeId: recipe.id)
        } else {
            // It's not favorited, so add it
            saveRecipeToFavorites(recipe: recipe)
        }
    }

    // NEW: Save a recipe to favorites collection
    private func saveRecipeToFavorites(recipe: GeneratedRecipe) {
        guard let userId = userId else { return }
        errorMessage = nil
        do {
            // Use setDoc with merge: false to overwrite or add, using recipe.id as document ID
            try db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/favoriteRecipes").document(recipe.id)
                .setData(from: recipe) { error in // Save the entire GeneratedRecipe model
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Error saving favorite: \(error.localizedDescription)"
                        } else {
                            print("Recipe favorited successfully: \(recipe.recipeName)")
                            // The listener will update favoriteRecipes list
                        }
                    }
                }
        } catch {
            errorMessage = "Error encoding favorite recipe: \(error.localizedDescription)"
        }
    }

    // NEW: Remove a recipe from favorites collection
    private func removeRecipeFromFavorites(recipeId: String) {
        guard let userId = userId else { return }
        errorMessage = nil
        db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/favoriteRecipes").document(recipeId).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error removing favorite: \(error.localizedDescription)"
                } else {
                    print("Recipe unfavorited successfully: \(recipeId)")
                    // The listener will update favoriteRecipes list
                }
            }
        }
    }
    
    // NEW: Asynchronous function to generate a full daily meal plan
    func generateDailyMealPlan() async {
        if !FirebaseManager.shared.isAuthReady || FirebaseManager.shared.userId == nil {
            errorMessage = "App not ready. Please wait for authentication to complete."
            return
        }
        // No need for `let userId = FirebaseManager.shared.userId!` here, as it's part of the class `userId` property.

        guard profileViewModel.userProfile.calorieTarget > 0 else {
            errorMessage = "Please save your user settings (weight, height, age, goal) first to calculate calorie targets."
            return
        }

        isLoading = true
        errorMessage = nil
        dailyMealPlan = nil // Clear previous plan

        let targetCalories = profileViewModel.userProfile.calorieTarget
        let targetProtein = profileViewModel.userProfile.proteinTarget
        let targetCarbs = profileViewModel.userProfile.carbTarget
        let targetFat = profileViewModel.userProfile.fatTarget
        let dietaryRestrictions = profileViewModel.userProfile.dietaryRestrictions

        let today = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }()
        let prompt = """
            You are an AI-powered meal planner. Generate a full daily meal plan in JSON format.
            The plan should include Breakfast, Lunch, Dinner, and 1-2 Snacks.
            The total nutritional values for the day should aim to meet the user's targets.

            - User Profile: Age \(profileViewModel.userProfile.age), Gender \(profileViewModel.userProfile.gender), Activity Level \(profileViewModel.userProfile.activityLevel).
            - Weight Goal: \(profileViewModel.userProfile.goal) weight.
            - Daily Nutritional Targets:
              * Total Calories: \(targetCalories) kcal
              * Total Protein: \(targetProtein)g
              * Total Carbs: \(targetCarbs)g
              * Total Fat: \(targetFat)g
            - Dietary Restrictions: \(dietaryRestrictions.isEmpty ? "None" : dietaryRestrictions).

            IMPORTANT: The output MUST be a valid JSON object with the following structure.
            {
              "date": "\(today)",
              "totalCalories": number,
              "totalProtein": number,
              "totalCarbs": number,
              "totalFat": number,
              "meals": [
                {
                  "mealType": "Breakfast",
                  "recipeName": "string",
                  "calories": number,
                  "protein": number,
                  "carbs": number,
                  "fat": number
                },
              ]
            }
            """
        
        do {
            let jsonData = try await generateJSON(prompt)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let mealPlan = try decoder.decode(DailyMealPlan.self, from: jsonData)
            self.dailyMealPlan = mealPlan
            print("Daily meal plan generated for \(mealPlan.date)")
            self.errorMessage = nil

        } catch {
            self.errorMessage = "Failed to generate daily meal plan: \(error.localizedDescription)"
            print(self.errorMessage!)
        }
        isLoading = false
    }
}

