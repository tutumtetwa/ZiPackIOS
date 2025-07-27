// MARK: - Models.swift
//
//  Models.swift
//  AI Personal Chef & Meal Planner
//
//  Created by Tutu  on 2025-07-12.
//

import Foundation // For Codable, UUID
import FirebaseFirestore // For Timestamp, DocumentID
import FirebaseFirestoreSwift // For @DocumentID

// MARK: - String Extension for JSON Escaping
// This extension helps ensure that strings interpolated into JSON are properly escaped.
extension String {
    func jsonEscaped() -> String {
        return self
            .replacingOccurrences(of: "\\", with: "\\\\") // Escape backslashes first
            .replacingOccurrences(of: "\"", with: "\\\"") // Escape double quotes
            .replacingOccurrences(of: "\n", with: "\\n") // Escape newlines
            .replacingOccurrences(of: "\t", with: "\\t") // Escape tabs
    }
}

// Nutritional constants for BMR/TDEE calculation
let BMR_WOMEN_CONST: Double = 655.1
let BMR_MEN_CONST: Double = 66.5
let BMR_WEIGHT_MULTIPLIER: Double = 13.7
let BMR_HEIGHT_MULTIPLIER: Double = 5.0
let BMR_AGE_MULTIPLIER: Double = 6.75

let ACTIVITY_MULTIPLIERS: [String: Double] = [
    "sedentary": 1.2,
    "lightly_active": 1.375,
    "moderately_active": 1.55,
    "very_active": 1.725,
    "extra_active": 1.9,
];

// MARK: User Profile Model
struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String? = "profile" // Firestore document ID for the single profile document
    var weight: Double
    var height: Double
    var age: Int
    var gender: String
    var activityLevel: String
    var goal: String // "maintain", "lose", "gain"
    var calorieTarget: Int
    var proteinTarget: Int
    var carbTarget: Int
    var fatTarget: Int
    var dietaryRestrictions: String // e.g., "vegetarian, gluten-free"

    // Initializer for default values
    init(weight: Double = 0, height: Double = 0, age: Int = 0, gender: String = "male", activityLevel: String = "sedentary", goal: String = "maintain", calorieTarget: Int = 0, proteinTarget: Int = 0, carbTarget: Int = 0, fatTarget: Int = 0, dietaryRestrictions: String = "") {
        self.weight = weight
        self.height = height
        self.age = age
        self.gender = gender
        self.activityLevel = activityLevel
        self.goal = goal
        self.calorieTarget = calorieTarget
        self.proteinTarget = proteinTarget
        self.carbTarget = carbTarget
        self.fatTarget = fatTarget
        self.dietaryRestrictions = dietaryRestrictions
    }
}

// MARK: Weight Entry Model
struct WeightEntry: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID
    var weight: Double
    var timestamp: Timestamp // Firestore Timestamp for date/time
}

// MARK: Pantry Item Model
struct PantryItem: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID
    var name: String
    var addedAt: Timestamp
    var expirationDate: String? // Stored as YYYY-MM-DD string for simplicity with DatePicker
}

// MARK: Logged Meal Model
struct LoggedMeal: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID
    var recipeName: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var timestamp: Timestamp
    var source: String // "generated" or "manual"
    var recipeId: String? // New: To track the ID of the generated recipe if logged
}

// MARK: Recipe Feedback Model
struct RecipeFeedback: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID
    var recipeName: String
    var recipeId: String // ID of the recipe that was logged (if applicable)
    var rating: Int // 1-5 stars
    var feedback: String
    var timestamp: Timestamp
}

// MARK: - Nutritional Info Model (Used by GeneratedRecipe and MealPlanEntry)
struct NutritionalInfo: Codable {
    let calories: Int
    let proteinGrams: Int
    let carbsGrams: Int
    let fatGrams: Int

    // No need for CodingKeys enum if property names match JSON keys
    // enum CodingKeys: String, CodingKey {
    //     case calories, proteinGrams, carbsGrams, fatGrams
    // }
}


// MARK: AI-Generated Recipe Model (Client-side representation)
struct GeneratedRecipe: Codable, Identifiable, Equatable { // Added Equatable
    let id: String // Firestore will assign this if saved, but for simulation, use UUID
    let recipeName: String
    let description: String
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int
    let ingredients: [String]
    let instructions: [String]
    let nutritionalInfo: NutritionalInfo? // Made optional as per your previous definition
    let notes: String? // Made optional as per your previous definition
    var isFavorite: Bool? = false // Optional, defaults to false
    var isLoggedToday: Bool? = false // Optional, defaults to false

    // Custom initializer to handle 'id' generation when decoding from AI (simulated JSON)
    // Firestore's @DocumentID handles it when reading from Firestore
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.recipeName = try container.decode(String.self, forKey: .recipeName)
        self.description = try container.decode(String.self, forKey: .description)
        self.prepTimeMinutes = try container.decode(Int.self, forKey: .prepTimeMinutes)
        self.cookTimeMinutes = try container.decode(Int.self, forKey: .cookTimeMinutes)
        self.servings = try container.decode(Int.self, forKey: .servings)
        self.ingredients = try container.decode([String].self, forKey: .ingredients)
        self.instructions = try container.decode([String].self, forKey: .instructions)
        self.nutritionalInfo = try container.decodeIfPresent(NutritionalInfo.self, forKey: .nutritionalInfo)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite)
        self.isLoggedToday = try container.decodeIfPresent(Bool.self, forKey: .isLoggedToday)

        // Generate a simple ID for local/simulated recipes if not coming from Firestore
        // This will create a new ID every time, which might not be desired if you want a stable ID for the same "simulated" recipe.
        // A more stable approach might be to hash recipeName + description for a consistent ID for generated recipes.
        // For now, UUID is fine for distinctness.
        self.id = UUID().uuidString
    }
    
    // For Equatable conformance
    static func == (lhs: GeneratedRecipe, rhs: GeneratedRecipe) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Daily Meal Plan Models
struct DailyMealPlan: Codable {
    var date: String
    var totalCalories: Int
    var totalProtein: Int
    var totalCarbs: Int
    var totalFat: Int
    var meals: [MealPlanEntry]
}

struct MealPlanEntry: Codable, Identifiable {
    // We will generate the ID during decoding, as the JSON doesn't provide it
    let id: String // This property MUST be `let` as it's part of Identifiable, and assigned in init.
    var mealType: String
    var recipeName: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var recipeID: String? // optional

    // Custom CodingKeys to explicitly map if needed (not strictly necessary here as names match)
    enum CodingKeys: String, CodingKey {
        case mealType, recipeName, calories, protein, carbs, fat, recipeID
    }

    // Custom initializer to handle decoding and ID generation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mealType = try container.decode(String.self, forKey: .mealType)
        self.recipeName = try container.decode(String.self, forKey: .recipeName)
        self.calories = try container.decode(Int.self, forKey: .calories)
        self.protein = try container.decode(Int.self, forKey: .protein)
        self.carbs = try container.decode(Int.self, forKey: .carbs)
        self.fat = try container.decode(Int.self, forKey: .fat)
        self.recipeID = try container.decodeIfPresent(String.self, forKey: .recipeID)

        // Generate a new UUID for the ID since it's not in the JSON payload
        self.id = UUID().uuidString
    }

    // You might want a regular initializer for programmatic creation
    init(mealType: String, recipeName: String, calories: Int, protein: Int, carbs: Int, fat: Int, recipeID: String? = nil) {
        self.id = UUID().uuidString
        self.mealType = mealType
        self.recipeName = recipeName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.recipeID = recipeID
    }
}

