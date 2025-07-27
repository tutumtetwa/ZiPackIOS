//
//  FirebaseManager.swift
//  Zipack
//
//  Created by Tutu on 7/12/25.
//

import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI // For @Published

// Define your app ID here. This is crucial for Firestore paths.
// REPLACE "com.yourname.AIPersonalChef" WITH YOUR ACTUAL XCODE PROJECT'S BUNDLE IDENTIFIER
let NATIVE_APP_ID = "tutu" // Changed to "tutu" as per console suggestion

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager() // Singleton instance
    let auth: Auth
    let db: Firestore
    @Published var userId: String?
    @Published var isAuthReady: Bool = false

    private init() {
        // FirebaseApp.configure() is called in the main App struct (AIPersonalChefApp.swift)
        // This ensures Firebase is initialized before we try to use it.
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        setupAuthListener()
    }

    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.userId = user.uid
                print("Signed in as: \(user.uid)")
                // Ensure UI updates on main thread
                DispatchQueue.main.async {
                    self.isAuthReady = true
                }
            } else {
                // If no user is signed in, attempt anonymous sign-in
                self.signInAnonymously()
            }
        }
    }

    private func signInAnonymously() {
        auth.signInAnonymously { authResult, error in
            if let error = error {
                print("Error signing in anonymously: \(error.localizedDescription)")
                // Ensure UI updates on main thread
                DispatchQueue.main.async {
                    self.isAuthReady = true // Mark ready even if sign-in failed to avoid infinite loading
                }
            } else if let uid = authResult?.user.uid {
                self.userId = uid
                print("Signed in anonymously: \(uid)")
                // Ensure UI updates on main thread
                DispatchQueue.main.async {
                    self.isAuthReady = true
                }
            }
        }
    }

    // Helper to get document reference for user-specific data
    func userDocRef(collectionPath: String, docId: String? = nil) -> DocumentReference {
        guard let userId = userId else {
            fatalError("User ID not available. Authentication must complete first.")
        }
        let basePath = "artifacts/\(NATIVE_APP_ID)/users/\(userId)/\(collectionPath)"
        if let docId = docId {
            return db.collection(basePath).document(docId)
        } else {
            return db.collection(basePath).document("profile") // Default for settings
        }
    }

    // Helper to get collection reference for user-specific data
    func userCollectionRef(collectionPath: String) -> CollectionReference {
        guard let userId = userId else {
            fatalError("User ID not available. Authentication must complete first.")
        }
        let basePath = "artifacts/\(NATIVE_APP_ID)/users/\(userId)/\(collectionPath)"
        return db.collection(basePath)
    }
}
