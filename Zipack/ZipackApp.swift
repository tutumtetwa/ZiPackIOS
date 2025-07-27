
import SwiftUI
import FirebaseCore // Required for FirebaseApp.configure()

@main
struct ZipackApp: App {
    // Initialize Firebase when the app starts
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // Instantiate all ViewModels here and provide them as environment objects.
            // This ensures they are singletons and accessible throughout the app.
            let firebaseManager = FirebaseManager.shared
            let profileVM = ProfileViewModel()
            let weightVM = WeightViewModel()
            let pantryVM = PantryViewModel()
            let mealLogVM = MealLogViewModel()
            
            // Explicitly initialize RecipeGenerationViewModel with its dependencies
            // This resolves potential ambiguity if the compiler can't infer the correct init
            let recipeGenVM = RecipeGenerationViewModel(
                profileViewModel: profileVM,
                pantryViewModel: pantryVM,
                mealLogViewModel: mealLogVM
            )

            // The main TabView for navigation
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }

                PantryView()
                    .tabItem {
                        Label("Pantry", systemImage: "carrot.fill")
                    }

                // Ensure RecipeGenerationView is correctly named and accessible
                RecipeGenerationView() // <--- CONFIRM THIS STRUCT NAME IS CORRECT IN YOUR FILE SYSTEM
                    .tabItem {
                        Label("Generate", systemImage: "sparkles")
                    }

                QuickAddMealView()
                    .tabItem {
                        Label("Log Meal", systemImage: "plus.circle.fill")
                    }
            }
            .accentColor(.purple) // Sets the tint color for selected tab items
            // Provide all ViewModels as environment objects
            .environmentObject(firebaseManager)
            .environmentObject(profileVM)
            .environmentObject(weightVM)
            .environmentObject(pantryVM)
            .environmentObject(mealLogVM)
            .environmentObject(recipeGenVM)
        }
    }
}
