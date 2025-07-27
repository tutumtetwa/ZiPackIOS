// MARK: - DashboardView.swift
//
//  DashboardView.swift
//  AI Personal Chef & Meal Planner
//
//  Created by Tutu on 2025-07-12.
//

import SwiftUI
import Charts // Import Charts framework for visualization

struct DashboardView: View {
    // Access ViewModels via EnvironmentObject as they are provided by the App struct
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @EnvironmentObject var weightVM: WeightViewModel
    @EnvironmentObject var pantryVM: PantryViewModel
    @EnvironmentObject var recipeGenVM: RecipeGenerationViewModel // For daily meal plan generation and favorite recipes

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Today's Nutrition Dashboard")
                        .font(.largeTitle).bold()
                        .foregroundColor(Color("AccentColor")) // Custom color from Assets
                        .padding(.bottom, 10)

                    // Circular Progress Indicators for Calories and Macros
                    NutritionProgressGrid(profileVM: profileVM, mealLogVM: mealLogVM)
                        .padding(.bottom)

                    // Logged Meals Section
                    SectionView(title: "Logged Meals Today", icon: Image(systemName: "list.bullet.rectangle.fill")) {
                        if mealLogVM.loggedMeals.filter({ Calendar.current.isDate($0.timestamp.dateValue(), inSameDayAs: Date()) }).isEmpty {
                            Text("No meals logged yet today.")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(mealLogVM.loggedMeals.filter { Calendar.current.isDate($0.timestamp.dateValue(), inSameDayAs: Date()) }) { meal in
                                HStack {
                                    Text(meal.recipeName)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(meal.calories) kcal (\(meal.protein)P/\(meal.carbs)C/\(meal.fat)F)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        Button(action: mealLogVM.clearDailyLog) {
                            Label("Clear Today's Log", systemImage: "trash.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.top)
                    }

                    // AI Coaching Insights Section
                    SectionView(title: "AI Coaching Insights", icon: Image(systemName: "sparkles")) {
                        // Extracted Coaching Insights into a dedicated sub-view
                        CoachingInsightsContent(profileVM: profileVM, mealLogVM: mealLogVM, weightVM: weightVM, pantryVM: pantryVM)
                    }

                    // NEW: Daily Meal Plan Section
                    SectionView(title: "Daily Meal Plan (AI Generated)", icon: Image(systemName: "calendar")) {
                        if let mealPlan = recipeGenVM.dailyMealPlan {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Plan for \(mealPlan.date)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("Total Estimated: \(mealPlan.totalCalories) kcal, \(mealPlan.totalProtein)P, \(mealPlan.totalCarbs)C, \(mealPlan.totalFat)F")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Divider()
                                
                                ForEach(mealPlan.meals) { mealEntry in
                                    HStack {
                                        Text(mealEntry.mealType)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(5)
                                        Text(mealEntry.recipeName)
                                            .font(.subheadline)
                                            .bold()
                                        Spacer()
                                        Text("\(mealEntry.calories) kcal")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        } else {
                            Text("No daily meal plan generated yet.")
                                .foregroundColor(.gray)
                                .italic()
                        }

                        Button {
                            Task {
                                await recipeGenVM.generateDailyMealPlan()
                            }
                        } label: {
                            Label(recipeGenVM.isLoading ? "Generating Plan..." : "Generate Daily Meal Plan", systemImage: "calendar.badge.plus")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.cyan]), startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .disabled(recipeGenVM.isLoading || profileVM.userProfile.calorieTarget == 0)
                        .padding(.top)
                    }
                    
                    // NEW: Favorite Recipes Section
                    SectionView(title: "Your Favorite Recipes", icon: Image(systemName: "heart.fill")) {
                        if recipeGenVM.favoriteRecipes.isEmpty {
                            Text("No favorite recipes yet. Mark some as favorite from the 'Generate' tab!")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(recipeGenVM.favoriteRecipes) { recipe in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(recipe.recipeName)
                                        .font(.headline)
                                    Text("\(recipe.nutritionalInfo?.calories ?? 0) kcal | \(recipe.prepTimeMinutes) min prep | \(recipe.cookTimeMinutes) min cook")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
                .padding() // Padding for the entire scroll view content
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true) // Hide default navigation bar for custom title
        }
    }
}

// MARK: - New Sub-Views to break up complexity
// These structs must be defined OUTSIDE DashboardView but within the same file.

// Extracted view for the circular progress indicators
struct NutritionProgressGrid: View {
    @ObservedObject var profileVM: ProfileViewModel // Use ObservedObject if passed directly
    @ObservedObject var mealLogVM: MealLogViewModel // Use ObservedObject if passed directly

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                CircularProgressView(
                    value: Double(mealLogVM.dailyConsumedCalories),
                    maxValue: Double(profileVM.userProfile.calorieTarget),
                    label: "Calories",
                    unit: "kcal",
                    pathColor: mealLogVM.dailyConsumedCalories > profileVM.userProfile.calorieTarget ? Color.red : Color.blue,
                    textColor: Color.blue
                )
                CircularProgressView(
                    value: Double(mealLogVM.dailyConsumedProtein),
                    maxValue: Double(profileVM.userProfile.proteinTarget),
                    label: "Protein",
                    unit: "g",
                    pathColor: Double(mealLogVM.dailyConsumedProtein) < Double(profileVM.userProfile.proteinTarget) * 0.75 ? Color.orange : Color.green,
                    textColor: Color.green
                )
            }
            HStack(spacing: 15) {
                CircularProgressView(
                    value: Double(mealLogVM.dailyConsumedCarbs),
                    maxValue: Double(profileVM.userProfile.carbTarget),
                    label: "Carbs",
                    unit: "g",
                    pathColor: Double(mealLogVM.dailyConsumedCarbs) > Double(profileVM.userProfile.carbTarget) * 1.25 ? Color.red : Color.orange,
                    textColor: Color.orange
                )
                CircularProgressView(
                    value: Double(mealLogVM.dailyConsumedFat),
                    maxValue: Double(profileVM.userProfile.fatTarget),
                    label: "Fat",
                    unit: "g",
                    pathColor: Double(mealLogVM.dailyConsumedFat) > Double(profileVM.userProfile.fatTarget) * 1.25 ? Color.red : Color.red.opacity(0.8),
                    textColor: Color.red.opacity(0.8)
                )
            }
        }
    }
}

// Extracted view for the coaching insights content
struct CoachingInsightsContent: View {
    @ObservedObject var profileVM: ProfileViewModel
    @ObservedObject var mealLogVM: MealLogViewModel
    @ObservedObject var weightVM: WeightViewModel
    @ObservedObject var pantryVM: PantryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Re-define boolean conditions with extreme explicitness
            let hasCalorieTarget: Bool = profileVM.userProfile.calorieTarget > 0

            let currentCaloriesDouble: Double = Double(mealLogVM.dailyConsumedCalories)
            let targetCaloriesDouble: Double = Double(profileVM.userProfile.calorieTarget)

            let isExceededCalories: Bool = hasCalorieTarget && (currentCaloriesDouble > targetCaloriesDouble * 1.1)
            let isBelowCalories: Bool = hasCalorieTarget && (currentCaloriesDouble < targetCaloriesDouble * 0.7)


            if isExceededCalories { // Use the new boolean variable
                let iconImage = Image(systemName: "arrow.up.circle.fill")
                CoachingInsightRow(text: "Warning: You've significantly exceeded your daily calorie target by \(mealLogVM.dailyConsumedCalories - profileVM.userProfile.calorieTarget) kcal today. Consider lighter options for your next meal or increasing activity tomorrow.", icon: iconImage, color: .red)
            }
            if isBelowCalories { // Use the new boolean variable
                let iconImage = Image(systemName: "arrow.down.circle.fill")
                CoachingInsightRow(text: "Heads up: You're significantly below your calorie target today. Ensure you're fueling your body adequately!", icon: iconImage, color: .orange)
            }
            if !pantryVM.getExpiringPantryItems().isEmpty {
                let iconImage = Image(systemName: "carrot.fill")
                CoachingInsightRow(text: "Don't forget! You have items like \(pantryVM.getExpiringPantryItems().map { $0.name }.joined(separator: ", ")) nearing expiration. Try to use them in your next generated recipe to reduce food waste!", icon: iconImage, color: .green)
            }
            if weightVM.weightHistory.count >= 2 {
                let latestWeight = weightVM.weightHistory.last?.weight ?? 0
                let secondLatestWeight = weightVM.weightHistory[weightVM.weightHistory.count - 2].weight
                if profileVM.userProfile.goal == "lose" {
                    if latestWeight >= secondLatestWeight {
                        let iconImage = Image(systemName: "exclamationmark.triangle.fill")
                        CoachingInsightRow(text: "Your recent weight log shows no loss. Let's review your calorie intake and activity level. Consistency is key!", icon: iconImage, color: .orange)
                    } else {
                        let iconImage = Image(systemName: "checkmark.circle.fill")
                        CoachingInsightRow(text: "Great job! Your weight is trending in the right direction for your loss goal. Keep up the good work!", icon: iconImage, color: .green)
                    }
                } else if profileVM.userProfile.goal == "gain" {
                    if latestWeight <= secondLatestWeight {
                        let iconImage = Image(systemName: "exclamationmark.triangle.fill")
                        CoachingInsightRow(text: "Your recent weight log shows no gain. Let's ensure you're consistently hitting your calorie surplus.", icon: iconImage, color: .orange)
                    } else {
                        let iconImage = Image(systemName: "checkmark.circle.fill")
                        CoachingInsightRow(text: "Excellent! You're making progress towards your weight gain goal.", icon: iconImage, color: .green)
                    }
                }
            }
            // Placeholder for Daily Meal Plan (now replaced by actual section above)
            // Text("Daily Meal Plan (Future AI Feature):")
            //     .font(.headline)
            //     .padding(.top, 6)
            // Text("(In a full native app, this section would dynamically display a full day's meal plan generated by the AI based on your goals, pantry, and schedule!)")
            //     .font(.caption)
            //     .foregroundColor(.gray)
            //     .italic()
        }
    }
}
