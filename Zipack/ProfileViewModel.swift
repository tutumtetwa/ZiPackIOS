// MARK: - ProfileViewModel.swift
//
//  ProfileViewModel.swift
//  AI Personal Chef & Meal Planner
//
//  Created by Gemini AI on 2025-07-12.
//

import Foundation
import FirebaseFirestore
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var db: Firestore { FirebaseManager.shared.db }
    private var userId: String? { FirebaseManager.shared.userId }
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.userProfile = UserProfile() // Initialize with default values
        setupProfileListener()
    }

    private func setupProfileListener() {
        // Listen for authentication readiness and user ID changes
        FirebaseManager.shared.$isAuthReady
            .filter { $0 } // Only proceed when Firebase is authenticated and ready
            .compactMap { _ in FirebaseManager.shared.userId } // Get the user ID
            .sink { [weak self] uid in
                guard let self = self else { return }
                // Ensure all UI-related updates happen on the main thread
                DispatchQueue.main.async {
                    self.isLoading = true
                }
                self.db.collection("artifacts/\(NATIVE_APP_ID)/users/\(uid)/settings").document("profile")
                    .addSnapshotListener { documentSnapshot, error in
                        // Ensure all UI-related updates happen on the main thread
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let error = error {
                                self.errorMessage = "Error fetching profile: \(error.localizedDescription)"
                                print(self.errorMessage!)
                                return
                            }
                            if let document = documentSnapshot, document.exists {
                                do {
                                    // Decode the document into our UserProfile model
                                    self.userProfile = try document.data(as: UserProfile.self)
                                    self.calculateTargets() // Recalculate targets whenever profile data changes
                                } catch {
                                    self.errorMessage = "Error decoding profile: \(error.localizedDescription)"
                                    print(self.errorMessage!)
                                }
                            } else {
                                // If the profile document doesn't exist, save a default one
                                self.saveProfile()
                            }
                        }
                    }
            }
            .store(in: &cancellables) // Store the subscription to prevent it from being cancelled prematurely
    }

    func saveProfile() {
        guard let userId = userId else {
            errorMessage = "User not authenticated. Please wait for authentication."
            return
        }
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            // Set the document data from the userProfile model
            try db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/settings").document("profile")
                .setData(from: userProfile, merge: true) { error in // merge: true allows partial updates
                    // Ensure all UI-related updates happen on the main thread
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = "Error saving profile: \(error.localizedDescription)"
                        } else {
                            print("Profile saved successfully.")
                            self.calculateTargets() // Ensure targets are calculated after save
                        }
                    }
                }
        } catch {
            // Ensure UI updates on main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error encoding profile: \(error.localizedDescription)"
            }
        }
    }

    // Calculates Basal Metabolic Rate (BMR) and Total Daily Energy Expenditure (TDEE)
    // and then sets calorie and macro targets based on the user's goal.
    func calculateTargets() {
        let profile = userProfile
        // Ensure necessary profile data is available for calculation
        guard profile.weight > 0, profile.height > 0, profile.age > 0 else {
            // Ensure UI updates on main thread
            DispatchQueue.main.async {
                self.userProfile.calorieTarget = 0
                self.userProfile.proteinTarget = 0
                self.userProfile.carbTarget = 0
                self.userProfile.fatTarget = 0
            }
            return
        }

        var bmr: Double
        let w = profile.weight
        let h = profile.height
        let a = Double(profile.age)

        // Mifflin-St Jeor Equation for BMR
        if profile.gender == "male" {
            // Break down the expression into smaller calculations
            let term1 = BMR_MEN_CONST
            let term2 = BMR_WEIGHT_MULTIPLIER * w
            let term3 = BMR_HEIGHT_MULTIPLIER * h
            let term4 = BMR_AGE_MULTIPLIER * a
            bmr = term1 + term2 + term3 - term4
        } else {
            // Break down the expression into smaller calculations
            let term1 = BMR_WOMEN_CONST
            let term2 = BMR_WEIGHT_MULTIPLIER * w
            let term3 = BMR_HEIGHT_MULTIPLIER * h
            let term4 = BMR_AGE_MULTIPLIER * a
            bmr = term1 + term2 + term3 - term4
        }

        // Calculate TDEE using activity multiplier
        let tdee = bmr * (ACTIVITY_MULTIPLIERS[profile.activityLevel] ?? 1.2);

        var targetCalories = tdee
        // Adjust calories based on weight goal
        if profile.goal == "lose" {
            targetCalories = max(1200, tdee - 500); // 500 kcal deficit for weight loss, with a minimum of 1200 kcal
        } else if profile.goal == "gain" {
            targetCalories += 500; // 500 kcal surplus for weight gain
        }

        // Simple macro split (can be made more sophisticated based on user preferences/dietary science)
        // Protein: 25% of calories (4 cal/g)
        // Carbs: 45% of calories (4 cal/g)
        // Fat: 30% of calories (9 cal/g)
        let proteinCals = targetCalories * 0.25;
        let carbCals = targetCalories * 0.45;
        let fatCals = targetCalories * 0.30;

        // Update userProfile properties (which are @Published, so views will react)
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            self.userProfile.calorieTarget = Int(round(targetCalories))
            self.userProfile.proteinTarget = Int(round(proteinCals / 4))
            self.userProfile.carbTarget = Int(round(carbCals / 4))
            self.userProfile.fatTarget = Int(round(fatCals / 9))
        }
    }
}
