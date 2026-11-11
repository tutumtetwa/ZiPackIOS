# 🍏 ZiPack: Your Personal Chef & Nutrition Companion (iOS App)



Welcome to **ZiPack**, a native iOS application built with Xcode, designed to be your intelligent personal chef and nutrition companion. This app helps you manage your diet, track your progress, and discover delicious, tailored recipes, leveraging the power of Firebase for robust data management and Google Gemini for personalized AI-driven culinary suggestions.

**Note:** This repository contains the **Xcode project source code** for the ZiPack iOS application. It is not currently available on the Apple App Store. You can clone this repository and run the app on your iOS simulator or a physical device using Xcode.

---

## ✨ Features

ZiPack aims to simplify healthy eating and tracking directly on your iPhone, offering:

* **📊 Personalized Nutrition Dashboard:**
    * Track daily calorie, protein, carb, and fat consumption against your personal targets.
    * Visualize your progress with intuitive displays.
* **👤 Customizable User Profiles:**
    * Set personal metrics like weight, height, age, gender, and activity level.
    * Define your weight goal (maintain, lose, gain) to automatically calculate personalized macro targets.
    * Input dietary restrictions to ensure all generated recipes align with your needs.
* **⚖️ Integrated Weight Tracking:**
    * Log your weight history and view your progress over time on a dynamic chart.
* **🥕 Smart Pantry Management:**
    * Add and remove ingredients from your virtual pantry.
    * Receive alerts for expiring or expired items to help reduce food waste.
* **🌟 AI-Powered Recipe Generation (Google Gemini):**
    * Generate unique recipes based on your profile, nutritional targets, and available pantry items (prioritizing expiring ones!).
    * Customize recipe generation with preferences like cuisine, meal type, cooking time, servings, excluded/included ingredients, spice level, and cooking method.
    * Refine previously generated recipes for new variations.
* **📅 Daily Meal Planning (Google Gemini):**
    * Generate a full day's meal plan (breakfast, lunch, dinner) tailored to your remaining calorie and macro targets.
* **✔️ Meal Logging:**
    * Quickly log generated recipes or manually add meals with custom nutritional information.
    * See a daily summary of consumed meals.
* **❤️ Favorite Recipes:**
    * Save your favorite AI-generated recipes for easy access and re-use.
* **👍 Recipe Feedback:**
    * Rate and provide feedback on generated recipes to help improve the AI's future suggestions.
* **🚀 Seamless Authentication:**
    * Utilizes Firebase anonymous authentication for a quick and secure onboarding experience without requiring personal logins initially.
* **💡 Coaching Insights:**
    * Receive smart advice based on your logged data, such as calorie intake warnings, weight goal progress, and reminders to use expiring pantry items.

---

## 🛠️ Technologies Used

* **Platform:** iOS
* **Development Environment:** Xcode
* **Programming Language:** Swift / SwiftUI
  
* **Backend & Services:**
    * **Firebase (Google Cloud Platform):**
        * **Firestore:** NoSQL database for storing user profiles, pantry items, meal logs, favorite recipes, and generated meal plans.
        * **Firebase Authentication:** For anonymous user authentication.
    * **Gemini 2.5 Flash via Firebase AI Logic:** generates personalized recipes and daily meal plans as structured JSON. Requests go through the Firebase project, so no API key is embedded in the app.
    * **External Libraries/SDKs:**
        * Firebase iOS SDK 12 (Auth, Firestore, FirebaseAI) via Swift Package Manager.
        * Charts Library 

---

## 🚀 Getting Started (Running the App Locally)

To run the ZiPack iOS app on your machine, follow these steps:

### 1. Prerequisites

* **Xcode:** Ensure you have Xcode installed on your macOS machine (download from the Mac App Store).
* **iOS Development Skills:** Basic familiarity with Xcode and iOS app development concepts is recommended.
* **Git:** Make sure Git is installed on your system.

### 2. Clone the Repository

Open your Terminal application and execute the following commands:

```bash
git clone https://github.com/tutumtetwa/ZiPackIOS.git
cd ZiPackIOS
open Zipack.xcodeproj

### 3. Enable Gemini (one time, per Firebase project)
In the Firebase console, open **AI Logic → Get started** and choose the **Gemini Developer API**. Recipe and meal-plan generation return an error until this is turned on.

**Live web companion:** https://zipack-42721.web.app
