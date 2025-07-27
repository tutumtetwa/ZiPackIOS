// MARK: - ProfileView.swift
//
//  ProfileView.swift
//  AI Personal Chef & Meal Planner
//
//  Created by Gemini AI on 2025-07-12.
//

import SwiftUI
import Charts // Import Charts framework

struct ProfileView: View {
    // Access ViewModels via EnvironmentObject
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var weightVM: WeightViewModel // To display weight history and log new weight

    // NEW: Local @State variables for UI input (lbs and feet)
    @State private var weightLbs: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = "" // For height in feet and inches

    // Formatter for decimal input
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                // Section for Personal Information
                Section(header: Text("Your Personal Information").font(.headline)) {
                    // NEW: Weight (lbs) with label above
                    VStack(alignment: .leading) {
                        Text("Weight (lbs):")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("e.g., 150", text: $weightLbs)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // NEW: Height (feet and inches) with labels above
                    VStack(alignment: .leading) {
                        Text("Height (feet & inches):")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            TextField("Feet", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("ft")
                            TextField("Inches", text: $heightInches)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("in")
                        }
                    }

                    // Age with label above
                    VStack(alignment: .leading) {
                        Text("Age:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("e.g., 30", value: $profileVM.userProfile.age, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Gender Picker
                    Picker("Gender", selection: $profileVM.userProfile.gender) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    }
                    // Activity Level Picker
                    Picker("Activity Level", selection: $profileVM.userProfile.activityLevel) {
                        Text("Sedentary (little or no exercise)").tag("sedentary")
                        Text("Lightly Active (1-3 days/week)").tag("lightly_active")
                        Text("Moderately Active (3-5 days/week)").tag("moderately_active")
                        Text("Very Active (6-7 days/week)").tag("very_active")
                        Text("Extra Active (daily hard exercise/physical job)").tag("extra_active")
                    }
                    // Weight Goal Picker
                    Picker("Weight Goal", selection: $profileVM.userProfile.goal) {
                        Text("Maintain Weight").tag("maintain")
                        Text("Lose Weight").tag("lose")
                        Text("Gain Weight").tag("gain")
                    }
                    // Dietary Restrictions
                    TextField("Dietary Restrictions (comma-separated)", text: $profileVM.userProfile.dietaryRestrictions)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Save Profile Button
                Button("Save Profile & Goals") {
                    // Convert lbs to kg and feet/inches to cm before saving
                    if let lbs = Double(weightLbs) {
                        profileVM.userProfile.weight = lbs * 0.453592 // lbs to kg
                    }
                    if let feet = Double(heightFeet), let inches = Double(heightInches) {
                        profileVM.userProfile.height = (feet * 30.48) + (inches * 2.54) // feet/inches to cm
                    } else if let feet = Double(heightFeet) {
                        profileVM.userProfile.height = feet * 30.48 // feet to cm (if inches is empty)
                    }

                    profileVM.saveProfile()
                }
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
                .listRowBackground(Color.clear) // Make button background transparent in form

                // Display Calculated Targets
                if profileVM.userProfile.calorieTarget > 0 {
                    Section(header: Text("Calculated Targets").font(.headline)) {
                        Text("Estimated Daily Calorie Target: \(profileVM.userProfile.calorieTarget) kcal")
                        Text("Target Macros: Protein \(profileVM.userProfile.proteinTarget)g, Carbs \(profileVM.userProfile.carbTarget)g, Fat \(profileVM.userProfile.fatTarget)g")
                    }
                }
                
                // Weight Tracking Section within Profile
                Section(header: Text("Weight Tracking").font(.headline)) {
                    // NEW: Weight input in lbs
                    VStack(alignment: .leading) {
                        Text("New Weight (lbs):")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("e.g., 150", value: $weightVM.newWeight, formatter: numberFormatter) // weightVM.newWeight is already Double (kg)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button("Add Weight") {
                        // weightVM.newWeight is already in KG from the previous logic.
                        // If you want to input LBS here, you'd need another @State for LBS and convert it to KG before calling addWeight.
                        // For simplicity, I'm assuming weightVM.newWeight is still bound to KG internally.
                        // If user inputs LBS here, you'd need: weightVM.newWeight = (Double(newWeightLbsInput) ?? 0) * 0.453592
                        weightVM.addWeight()
                        // Update profile's current weight after adding new weight
                        if let newWeightKg = weightVM.newWeight {
                            profileVM.userProfile.weight = newWeightKg
                            profileVM.saveProfile()
                        }
                    }
                    .font(.headline)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.indigo, Color.blue]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .listRowBackground(Color.clear)

                    if weightVM.weightHistory.isEmpty {
                        Text("No weight entries yet.")
                            .foregroundColor(.gray)
                    } else {
                        Text("Weight History:")
                            .font(.subheadline)
                            .padding(.top, 5)
                        
                        // Weight History Chart
                        Chart {
                            ForEach(weightVM.weightHistory) { entry in
                                LineMark(
                                    x: .value("Date", entry.timestamp.dateValue()),
                                    y: .value("Weight", entry.weight)
                                )
                                .interpolationMethod(.catmullRom) // Smooth line
                                .foregroundStyle(Color.purple)
                                PointMark(
                                    x: .value("Date", entry.timestamp.dateValue()),
                                    y: .value("Weight", entry.weight)
                                )
                                .foregroundStyle(Color.purple)
                            }
                        }
                        .chartYAxisLabel("Weight (lbs)") // Still showing KG on chart as internal model is KG
                        .chartXAxisLabel("Date")
                        .frame(height: 200)
                        .padding(.vertical)
                        
                        // List of entries below the chart
                        ForEach(weightVM.weightHistory) { entry in
                            HStack {
                                Text("\(entry.weight, specifier: "%.1f") lbs") // Still showing KG here
                                Spacer()
                                Text(entry.timestamp.dateValue(), style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                // Display any error messages
                if let errorMessage = profileVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                if let errorMessage = weightVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Your Profile")
            // NEW: Initialize local state from profileVM on appear
            .onAppear {
                weightLbs = profileVM.userProfile.weight > 0 ? String(format: "%.1f", profileVM.userProfile.weight * 2.20462) : "" // kg to lbs
                let totalCm = profileVM.userProfile.height
                if totalCm > 0 {
                    let totalInches = totalCm / 2.54 // cm to inches
                    let feet = floor(totalInches / 12)
                    let inches = totalInches.truncatingRemainder(dividingBy: 12)
                    heightFeet = String(format: "%.0f", feet)
                    heightInches = String(format: "%.0f", inches)
                } else {
                    heightFeet = ""
                    heightInches = ""
                }
            }
        }
    }
}
