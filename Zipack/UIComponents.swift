//
//  UIComponents.swift.swift
//  Zipack
//
//  Created by Tutu on 7/12/25.
//

import SwiftUI

// Reusable Section View for consistent styling
struct SectionView<Content: View>: View {
    let title: String
    let icon: Image
    let content: Content

    init(title: String, icon: Image, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                icon
                    .font(.title3)
                    .foregroundColor(Color("SectionIconColor")) // Custom color from Assets
                Text(title)
                    .font(.title2).bold()
                    .foregroundColor(Color("SectionTitleColor")) // Custom color from Assets
            }
            .padding(.bottom, 5)

            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal) // Add horizontal padding to the section view itself
    }
}

// Custom Circular Progress View (Placeholder for a more advanced implementation)
struct CircularProgressView: View {
    var value: Double
    var maxValue: Double
    var label: String
    var unit: String
    var pathColor: Color // Color for the progress path
    var textColor: Color // Color for the text

    var body: some View {
        VStack {
            ZStack {
                // Background circle (the "track" of the progress bar)
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                // The progress path
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(value / maxValue, 1.0))) // Trim based on progress
                    .stroke(pathColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Start from the top
                    .animation(.easeOut, value: value) // Animate changes
                    .frame(width: 100, height: 100)

                // Text displaying the current value
                Text("\(Int(value)) \(unit)")
                    .font(.title2).bold()
                    .foregroundColor(textColor)
            }
            .frame(width: 100, height: 100) // Ensure consistent size for the ZStack content

            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            Text("Target: \(Int(maxValue)) \(unit)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}


// Reusable Row for Coaching Insights
struct CoachingInsightRow: View {
    let text: String
    let icon: Image // This should be an Image type
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            icon // The icon is passed directly as an Image
                .font(.body)
                .foregroundColor(color)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

