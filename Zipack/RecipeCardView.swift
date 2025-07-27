// MARK: - RecipeCardView.swift
//
//  RecipeCardView.swift
//  AI Personal Chef & Meal Planner
//
//  Created by Tutu on 2025-07-12.
//

import SwiftUI
import UIKit // Required for UIActivityViewController (for sharing)

struct RecipeCardView: View {
    let recipe: GeneratedRecipe // The recipe to display
    @EnvironmentObject var recipeGenVM: RecipeGenerationViewModel // For feedback and refine, and favoriting
    @EnvironmentObject var mealLogVM: MealLogViewModel // For logging the meal

    @State private var showShareSheet: Bool = false // State for sharing sheet

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Recipe Name
            Text(recipe.recipeName)
                .font(.title2).bold()
                .foregroundColor(.yellow.opacity(0.8))

            // Recipe Description
            Text(recipe.description)
                .font(.body)
                .foregroundColor(.gray)

            // Prep, Cook Time & Servings
            HStack {
                Label("\(recipe.prepTimeMinutes) mins", systemImage: "hourglass")
                Label("\(recipe.cookTimeMinutes) mins", systemImage: "flame.fill")
                Label("\(recipe.servings) servings", systemImage: "person.3.fill")
            }
            .font(.subheadline)
            .foregroundColor(.gray)

            Divider()

            // Ingredients List
            Text("Ingredients:")
                .font(.headline)
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                Text("• \(ingredient)")
                    .font(.body)
            }

            Divider()

            // Instructions List
            Text("Instructions:")
                .font(.headline)
            ForEach(recipe.instructions.indices, id: \.self) { index in
                Text("\(index + 1). \(recipe.instructions[index])")
                    .font(.body)
                    .padding(.bottom, 2)
            }

            // Nutritional Info (if available)
            if let nutritionalInfo = recipe.nutritionalInfo {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Nutritional Info (Estimated):")
                        .font(.headline)
                    Text("Calories: \(nutritionalInfo.calories) kcal")
                    Text("Protein: \(nutritionalInfo.proteinGrams)g")
                    Text("Carbs: \(nutritionalInfo.carbsGrams)g")
                    Text("Fat: \(nutritionalInfo.fatGrams)g")
                }
                .font(.subheadline)
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(10)
            }

            // Notes / AI Rationale (if available)
            if let notes = recipe.notes, !notes.isEmpty {
                // Assuming notes might contain AI rationale based on previous prompt structure
                Text("Notes/AI Rationale: \(notes)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }

            // Action Buttons: Log Meal and Refine Recipe
            HStack {
                Button {
                    mealLogVM.logMeal(recipe: recipe)
                } label: {
                    Label(recipe.isLoggedToday == true ? "Logged Today!" : "Log This Meal", systemImage: "fork.knife")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        // FIX: Ensure consistent type for background (both are LinearGradient)
                        .background(recipe.isLoggedToday == true ? LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green.opacity(0.9)]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .disabled(recipe.isLoggedToday == true) // Disable if already logged today

                Button {
                    Task {
                        // Pass current preferences for refinement from the original generation request
                        // In a real app, you'd store these preferences in recipeGenVM or pass them down
                        await recipeGenVM.generateRecipe(
                            cuisinePreference: "", // Placeholder, ideally from stored state
                            mealType: "",          // Placeholder, ideally from stored state
                            cookingTime: "",       // Placeholder, ideally from stored state
                            servings: recipe.servings, // Use servings from the current recipe
                            excludedIngredients: "", // Placeholder
                            includedIngredients: "", // Placeholder
                            spiceLevel: "",          // Placeholder
                            cookingMethod: "",       // Placeholder
                            mealPrepFocus: false,    // Placeholder
                            refine: true
                        )
                    }
                } label: {
                    Label("Refine Recipe", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
            }
            .padding(.top, 10)

            // New: Share and Save/Print Options
            HStack(spacing: 10) {
                Button {
                    showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showShareSheet) {
                    ActivityViewController(activityItems: [formatRecipeForSharing(recipe: recipe)])
                }

                Button {
                    recipeGenVM.toggleFavorite(recipe: recipe)
                } label: {
                    Label("Favorite", systemImage: recipe.isFavorite == true ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(recipe.isFavorite == true ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                        .foregroundColor(recipe.isFavorite == true ? .red : .red)
                        .cornerRadius(10)
                }

                Button {
                    // Basic print functionality
                    let printController = UIPrintInteractionController.shared
                    let printInfo = UIPrintInfo(dictionary: nil)
                    printInfo.outputType = .general
                    printInfo.jobName = recipe.recipeName
                    printController.printInfo = printInfo
                    
                    // Create a simple text formatter for printing
                    let formatter = UIMarkupTextPrintFormatter(markupText: formatRecipeForHTMLPrint(recipe: recipe))
                    printController.printFormatter = formatter
                    
                    printController.present(animated: true, completionHandler: nil)

                } label: {
                    Label("Print", systemImage: "printer")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 10)

            // Recipe Feedback Section
            VStack(alignment: .leading) {
                Text("Rate & Give Feedback:")
                    .font(.headline)
                HStack {
                    ForEach(1..<6) { star in
                        Image(systemName: star <= recipeGenVM.recipeRating ? "star.fill" : "star")
                            .foregroundColor(star <= recipeGenVM.recipeRating ? .yellow : .gray)
                            .font(.title2)
                            .onTapGesture {
                                recipeGenVM.recipeRating = star
                            }
                    }
                }
                TextEditor(text: $recipeGenVM.recipeFeedback)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .padding(.vertical, 5)
                
                // FIX: Call the ViewModel function directly on its wrappedValue
                Button("Submit Feedback") {
                    _recipeGenVM.wrappedValue.submitRecipeFeedback() // Explicitly call on wrappedValue
                }
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.top, 20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // Helper function to format recipe for sharing
    private func formatRecipeForSharing(recipe: GeneratedRecipe) -> String {
        var shareText = "\(recipe.recipeName)\n\n"
        shareText += "\(recipe.description)\n\n"
        shareText += "Prep: \(recipe.prepTimeMinutes)min, Cook: \(recipe.cookTimeMinutes)min, Servings: \(recipe.servings)\n\n"
        shareText += "Ingredients:\n"
        recipe.ingredients.forEach { shareText += "- \($0)\n" }
        shareText += "\nInstructions:\n"
        recipe.instructions.enumerated().forEach { index, instruction in
            shareText += "\(index + 1). \(instruction)\n"
        }
        if let info = recipe.nutritionalInfo {
            shareText += "\nNutritional Info (Est.): \(info.calories)kcal, \(info.proteinGrams)P, \(info.carbsGrams)C, \(info.fatGrams)F\n"
        }
        if let notes = recipe.notes, !notes.isEmpty {
            shareText += "\nNotes: \(notes)\n"
        }
        shareText += "\n#AIPersonalChef"
        return shareText
    }
    
    // NEW: Helper function to format recipe for HTML printing
    private func formatRecipeForHTMLPrint(recipe: GeneratedRecipe) -> String {
        var html = """
        <html>
        <head>
            <style>
                body { font-family: sans-serif; margin: 20px; }
                h1 { color: #8B5CF6; }
                h2 { color: #EC4899; }
                ul, ol { margin-left: 20px; }
                .nutrition-info { background-color: #F3F4F6; padding: 10px; border-radius: 8px; margin-top: 15px; }
                .key-stats { display: flex; gap: 20px; margin-bottom: 15px;}
                .key-stats div { flex: 1; text-align: center; background-color: #E0E7FF; padding: 10px; border-radius: 8px;}
            </style>
        </head>
        <body>
            <h1>\(recipe.recipeName)</h1>
            <p><i>\(recipe.description)</i></p>
            <div class="key-stats">
                <div><strong>Prep Time:</strong> \(recipe.prepTimeMinutes) mins</div>
                <div><strong>Cook Time:</strong> \(recipe.cookTimeMinutes) mins</div>
                <div><strong>Servings:</strong> \(recipe.servings)</div>
            </div>
            <h2>Ingredients:</h2>
            <ul>
        """
        recipe.ingredients.forEach { html += "<li>\($0)</li>" }
        html += """
            </ul>
            <h2>Instructions:</h2>
            <ol>
        """
        recipe.instructions.enumerated().forEach { index, instruction in
            html += "<li>\(index + 1). \(instruction)</li>"
        }
        html += """
            </ol>
        """
        if let info = recipe.nutritionalInfo {
            html += """
            <div class="nutrition-info">
                <h3>Nutritional Info (Estimated):</h3>
                <p><strong>Calories:</strong> \(info.calories) kcal</p>
                <p><strong>Protein:</strong> \(info.proteinGrams)g</p>
                <p><strong>Carbs:</strong> \(info.carbsGrams)g</p>
                <p><strong>Fat:</strong> \(info.fatGrams)g</p>
            </div>
            """
        }
        if let notes = recipe.notes, !notes.isEmpty {
            html += """
            <p><strong>Notes/AI Rationale:</strong> \(notes)</p>
            """
        }
        html += """
        </body>
        </html>
        """
        return html
    }
}

// New: UIViewControllerRepresentable for UIActivityViewController (Share Sheet)
import UIKit // Required for UIActivityViewController

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}
